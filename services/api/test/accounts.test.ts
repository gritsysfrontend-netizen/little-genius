import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { PrismaClient } from '@prisma/client';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import type { AppConfig } from '../src/config.js';
import { drainOneJob } from '../src/modules/accounts/jobs.js';
import { TestIdentityProvider, testAuthorization } from '../src/modules/admin/identity.js';
import { defaultFixtureDir, defaultSchemaPath, seedDatabase } from '../src/seed.js';

const prisma = new PrismaClient();
let app: FastifyInstance;
let sequence = 0;

const config: AppConfig = {
  assetSigningKey: 'test-signing-key',
  publicBaseUrl: 'http://127.0.0.1:3000',
  fixtureDir: defaultFixtureDir(),
  schemaPath: defaultSchemaPath(),
  rateManifest: 60,
  rateLesson: 120,
  rateAsset: 120,
  rateAdmin: 60,
  rateEvents: 30,
  identityProvider: 'deny',
  cognito: null,
  assetUrlTtlSeconds: 300,
  host: '127.0.0.1',
  port: 3000,
};

function uuid(): string {
  sequence += 1;
  return `00000000-0000-4000-8000-${sequence.toString(16).padStart(12, '0')}`;
}

function parentToken(sub: string, reauthenticated = false): string {
  return testAuthorization({ sub, aud: 'parent', mfa: false, reauthenticated });
}

function comparable(response: { statusCode: number; json: () => unknown }) {
  const body = response.json() as {
    error: { code: string; message: string; retryable: boolean };
  };
  return {
    status: response.statusCode,
    code: body.error.code,
    message: body.error.message,
    retryable: body.error.retryable,
  };
}

async function cleanup(): Promise<void> {
  const parents = await prisma.parentAccount.findMany({
    where: { authProviderSub: { startsWith: 'parent-test-' } },
    select: { id: true },
  });
  const ids = parents.map((parent) => parent.id);
  if (ids.length === 0) return;
  const profiles = await prisma.childProfile.findMany({
    where: { parentAccountId: { in: ids } },
    select: { id: true },
  });
  const profileIds = profiles.map((profile) => profile.id);
  await prisma.jobOutbox.deleteMany({ where: { parentAccountId: { in: ids } } });
  await prisma.idempotencyKey.deleteMany({ where: { parentAccountId: { in: ids } } });
  await prisma.consentRecord.deleteMany({ where: { parentAccountId: { in: ids } } });
  if (profileIds.length > 0) {
    await prisma.learningEvent.deleteMany({ where: { profileId: { in: profileIds } } });
    await prisma.progressSummary.deleteMany({ where: { profileId: { in: profileIds } } });
  }
  await prisma.childProfile.deleteMany({ where: { parentAccountId: { in: ids } } });
  await prisma.parentAccount.deleteMany({ where: { id: { in: ids } } });
}

before(async () => {
  await cleanup();
  await seedDatabase(prisma, config.fixtureDir, config.schemaPath);
  app = await buildApp({
    prisma,
    config,
    identity: new TestIdentityProvider(),
    logger: false,
  });
});

after(async () => {
  await app.close();
  await cleanup();
  await prisma.$disconnect();
});

async function consent(sub: string): Promise<void> {
  const response = await app.inject({
    method: 'POST',
    url: '/api/v1/privacy/consent',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: JSON.stringify({
      purpose: 'account_sync',
      noticeVersion: 'account-sync-1',
      decision: 'granted',
    }),
  });
  assert.equal(response.statusCode, 201, response.body);
}

function profilePayload(profileId: string, nickname = 'Asha'): string {
  return JSON.stringify({
    clientProfileId: profileId,
    nickname,
    avatarId: 'leaf',
    ageBand: '2-3',
    preferredLocale: 'ta',
    bilingualMode: true,
  });
}

test('a staff token and a missing token cannot call parent routes', async () => {
  const staff = testAuthorization({ sub: 'staff-on-parent', aud: 'staff', roles: ['author'] });
  const staffResponse = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: staff,
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: profilePayload(uuid()),
  });
  assert.equal(staffResponse.statusCode, 401);
  assert.equal(staffResponse.json().error.code, 'UNAUTHENTICATED');
  assert.equal(staffResponse.json().error.message, 'Parent sign-in is required.');

  const missing = await app.inject({ method: 'GET', url: '/api/v1/profiles' });
  assert.equal(missing.statusCode, 401);
  assert.equal(missing.json().error.code, 'UNAUTHENTICATED');

  const parentOnAdmin = await app.inject({
    method: 'GET',
    url: '/admin/v1/drafts',
    headers: { authorization: parentToken('parent-test-admin') },
  });
  assert.equal(parentOnAdmin.statusCode, 401);
  assert.equal(parentOnAdmin.json().error.message, 'Staff sign-in is required.');
});

test('consent is required before the first upload and clientProfileId is reused', async () => {
  const sub = 'parent-test-convert';
  const profileId = uuid();
  const blocked = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: profilePayload(profileId),
  });
  assert.equal(blocked.statusCode, 403);
  assert.equal(blocked.json().error.code, 'FORBIDDEN');

  await consent(sub);
  const raw = profilePayload(profileId);
  const key = uuid();
  const created = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': key,
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(created.statusCode, 201);
  assert.equal(created.json().profileId, profileId);

  const replay = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': key,
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(replay.statusCode, 201);
  assert.deepEqual(replay.json(), created.json());

  const retry = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(retry.statusCode, 200);
  assert.equal(retry.json().profileId, profileId);

  const reused = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': key,
      'content-type': 'application/json',
    },
    payload: profilePayload(profileId, 'Other'),
  });
  assert.equal(reused.statusCode, 409);
  assert.equal(reused.json().error.code, 'IDEMPOTENCY_KEY_REUSE');

  const account = await prisma.parentAccount.findUniqueOrThrow({ where: { authProviderSub: sub } });
  const count = await prisma.childProfile.count({ where: { parentAccountId: account.id } });
  assert.equal(count, 1);
  const saved = await prisma.childProfile.findUniqueOrThrow({ where: { id: profileId } });
  assert.equal(saved.nickname, 'Asha');

  await consent('parent-test-other');
  const conflict = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken('parent-test-other'),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(conflict.statusCode, 409);
  assert.equal(conflict.json().error.code, 'PROFILE_ID_CONFLICT');
  assert.equal(JSON.stringify(conflict.json()).includes(sub), false);
  assert.equal(JSON.stringify(conflict.json()).includes(account.id), false);
});

test('an altered profile id returns the same 404 body as a missing id', async () => {
  const owner = 'parent-test-owner';
  const other = 'parent-test-stranger';
  const profileId = uuid();
  await consent(owner);
  await consent(other);
  const created = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(owner),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: profilePayload(profileId, 'Meera'),
  });
  assert.equal(created.statusCode, 201);

  const missingId = uuid();
  const missing = await app.inject({
    method: 'GET',
    url: `/api/v1/profiles/${missingId}/progress`,
    headers: { authorization: parentToken(other) },
  });
  const altered = await app.inject({
    method: 'GET',
    url: `/api/v1/profiles/${profileId}/progress`,
    headers: { authorization: parentToken(other) },
  });
  assert.deepEqual(comparable(missing), comparable(altered));
  assert.equal(altered.statusCode, 404);
  assert.equal(altered.json().error.code, 'PROFILE_NOT_FOUND');
  assert.equal(JSON.stringify(altered.json()).includes('Meera'), false);
  assert.equal(JSON.stringify(altered.json()).includes(owner), false);
});

test('a duplicate event batch does not double-count', async () => {
  const sub = 'parent-test-events';
  const profileId = uuid();
  const eventId = uuid();
  await consent(sub);
  const created = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: profilePayload(profileId),
  });
  assert.equal(created.statusCode, 201);

  const raw = JSON.stringify({
    events: [
      {
        eventId,
        contentId: 'animal.elephant.001',
        contentVersion: 1,
        eventType: 'completed',
        occurredAt: '2026-10-29T12:00:00.000Z',
        durationBucket: 'lt_1m',
      },
    ],
  });
  const key = uuid();
  const first = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': key,
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(first.statusCode, 200, first.body);
  assert.deepEqual(first.json().applied, [eventId]);
  assert.deepEqual(first.json().duplicates, []);

  const progress = await app.inject({
    method: 'GET',
    url: `/api/v1/profiles/${profileId}/progress`,
    headers: { authorization: parentToken(sub) },
  });
  assert.equal(progress.statusCode, 200);
  assert.equal(progress.json().categories[0].categoryId, 'animals');
  assert.equal(progress.json().categories[0].completedCount, 1);
  assert.equal(progress.json().categories[0].startedCount, 0);

  const duplicate = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(duplicate.statusCode, 200);
  assert.deepEqual(duplicate.json().applied, []);
  assert.deepEqual(duplicate.json().duplicates, [eventId]);

  const replay = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': key,
      'content-type': 'application/json',
    },
    payload: raw,
  });
  assert.equal(replay.statusCode, 200);
  assert.deepEqual(replay.json(), first.json());

  const changed = raw.replace('lt_1m', 'm1_to_5');
  const reused = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': key,
      'content-type': 'application/json',
    },
    payload: changed,
  });
  assert.equal(reused.statusCode, 409);
  assert.equal(reused.json().error.code, 'IDEMPOTENCY_KEY_REUSE');

  const after = await app.inject({
    method: 'GET',
    url: `/api/v1/profiles/${profileId}/progress`,
    headers: { authorization: parentToken(sub) },
  });
  assert.equal(after.json().categories[0].completedCount, 1);
  const stored = await prisma.learningEvent.count({ where: { profileId } });
  assert.equal(stored, 1);

  const tooMany = {
    events: Array.from({ length: 51 }, () => ({
      eventId: uuid(),
      contentId: 'animal.elephant.001',
      contentVersion: 1,
      eventType: 'started',
      occurredAt: '2026-10-29T12:00:00.000Z',
    })),
  };
  const large = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: tooMany,
  });
  assert.equal(large.statusCode, 413);
  assert.equal(large.json().error.code, 'PAYLOAD_TOO_LARGE');
  assert.equal(await prisma.learningEvent.count({ where: { profileId } }), 1);
});

test('deleting a profile removes events before the response', async () => {
  const sub = 'parent-test-profile';
  const profileId = uuid();
  const eventId = uuid();
  await consent(sub);
  assert.equal(
    (
      await app.inject({
        method: 'POST',
        url: '/api/v1/profiles',
        headers: {
          authorization: parentToken(sub),
          'idempotency-key': uuid(),
          'content-type': 'application/json',
        },
        payload: profilePayload(profileId),
      })
    ).statusCode,
    201,
  );
  assert.equal(
    (
      await app.inject({
        method: 'POST',
        url: `/api/v1/profiles/${profileId}/events:batch`,
        headers: {
          authorization: parentToken(sub),
          'idempotency-key': uuid(),
          'content-type': 'application/json',
        },
        payload: {
          events: [
            {
              eventId,
              contentId: 'animal.elephant.001',
              contentVersion: 1,
              eventType: 'started',
              occurredAt: '2026-10-29T12:00:00.000Z',
            },
          ],
        },
      })
    ).statusCode,
    200,
  );
  const deleted = await app.inject({
    method: 'DELETE',
    url: `/api/v1/profiles/${profileId}`,
    headers: { authorization: parentToken(sub), 'idempotency-key': uuid() },
  });
  assert.equal(deleted.statusCode, 202);
  assert.deepEqual(deleted.json(), { status: 'deleted' });
  assert.equal(await prisma.learningEvent.count({ where: { eventId } }), 0);
  const missingId = uuid();
  const missing = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${missingId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: {
      events: [
        {
          eventId: uuid(),
          contentId: 'animal.elephant.001',
          contentVersion: 1,
          eventType: 'started',
          occurredAt: '2026-10-29T12:00:00.000Z',
        },
      ],
    },
  });
  const again = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: {
      events: [
        {
          eventId: uuid(),
          contentId: 'animal.elephant.001',
          contentVersion: 1,
          eventType: 'started',
          occurredAt: '2026-10-29T12:00:00.000Z',
        },
      ],
    },
  });
  assert.deepEqual(comparable(missing), comparable(again));
  assert.equal(again.statusCode, 404);
});

test('account deletion stays pending until the job finishes', async () => {
  const sub = 'parent-test-delete';
  const profileId = uuid();
  const eventId = uuid();
  await consent(sub);
  assert.equal(
    (
      await app.inject({
        method: 'POST',
        url: '/api/v1/profiles',
        headers: {
          authorization: parentToken(sub),
          'idempotency-key': uuid(),
          'content-type': 'application/json',
        },
        payload: profilePayload(profileId, 'Ravi'),
      })
    ).statusCode,
    201,
  );
  assert.equal(
    (
      await app.inject({
        method: 'POST',
        url: `/api/v1/profiles/${profileId}/events:batch`,
        headers: {
          authorization: parentToken(sub),
          'idempotency-key': uuid(),
          'content-type': 'application/json',
        },
        payload: {
          events: [
            {
              eventId,
              contentId: 'animal.elephant.001',
              contentVersion: 1,
              eventType: 'completed',
              occurredAt: '2026-10-29T12:00:00.000Z',
            },
          ],
        },
      })
    ).statusCode,
    200,
  );

  const denied = await app.inject({
    method: 'POST',
    url: '/api/v1/privacy/delete-account',
    headers: { authorization: parentToken(sub), 'idempotency-key': uuid() },
  });
  assert.equal(denied.statusCode, 401);
  assert.equal(await prisma.jobOutbox.count({ where: { parent: { authProviderSub: sub } } }), 0);

  const accepted = await app.inject({
    method: 'POST',
    url: '/api/v1/privacy/delete-account',
    headers: {
      authorization: parentToken(sub, true),
      'idempotency-key': uuid(),
    },
  });
  assert.equal(accepted.statusCode, 202);
  assert.equal(accepted.json().status, 'pending');
  assert.equal(accepted.json().jobType, 'delete_account');
  assert.notEqual(accepted.json().status, 'completed');

  const stopped = await app.inject({
    method: 'POST',
    url: `/api/v1/profiles/${profileId}/events:batch`,
    headers: {
      authorization: parentToken(sub),
      'idempotency-key': uuid(),
      'content-type': 'application/json',
    },
    payload: {
      events: [
        {
          eventId: uuid(),
          contentId: 'animal.elephant.001',
          contentVersion: 1,
          eventType: 'started',
          occurredAt: '2026-10-29T12:05:00.000Z',
        },
      ],
    },
  });
  assert.equal(stopped.statusCode, 401);
  assert.equal(stopped.json().error.message, 'This session was revoked.');

  const pending = await app.inject({
    method: 'GET',
    url: `/api/v1/privacy/requests/${accepted.json().jobId}`,
    headers: { authorization: parentToken(sub) },
  });
  assert.equal(pending.statusCode, 200);
  assert.equal(pending.json().status, 'pending');
  assert.equal(await prisma.learningEvent.count({ where: { eventId } }), 1);
  const consents = await prisma.consentRecord.count({
    where: { parent: { authProviderSub: sub } },
  });
  assert.equal(consents, 1);

  const drained = await drainOneJob(prisma);
  assert.equal(drained, accepted.json().jobId);
  const finished = await app.inject({
    method: 'GET',
    url: `/api/v1/privacy/requests/${accepted.json().jobId}`,
    headers: { authorization: parentToken(sub) },
  });
  assert.equal(finished.statusCode, 200);
  assert.equal(finished.json().status, 'completed');
  assert.equal(await prisma.learningEvent.count({ where: { eventId } }), 0);
  assert.equal(
    await prisma.consentRecord.count({ where: { parent: { authProviderSub: sub } } }),
    1,
  );
  const profile = await prisma.childProfile.findUniqueOrThrow({ where: { id: profileId } });
  assert.equal(profile.nickname, '');
  assert.ok(profile.deletedAt);
});

test('export stays pending until the job finishes and does not return a file', async () => {
  const sub = 'parent-test-export';
  const profileId = uuid();
  await consent(sub);
  assert.equal(
    (
      await app.inject({
        method: 'POST',
        url: '/api/v1/profiles',
        headers: {
          authorization: parentToken(sub),
          'idempotency-key': uuid(),
          'content-type': 'application/json',
        },
        payload: profilePayload(profileId, 'Nila'),
      })
    ).statusCode,
    201,
  );
  const accepted = await app.inject({
    method: 'POST',
    url: '/api/v1/privacy/export',
    headers: { authorization: parentToken(sub), 'idempotency-key': uuid() },
  });
  assert.equal(accepted.statusCode, 202);
  assert.equal(accepted.json().status, 'pending');
  assert.equal(JSON.stringify(accepted.json()).includes('Nila'), false);
  assert.equal(await drainOneJob(prisma), accepted.json().jobId);
  const finished = await app.inject({
    method: 'GET',
    url: `/api/v1/privacy/requests/${accepted.json().jobId}`,
    headers: { authorization: parentToken(sub) },
  });
  assert.equal(finished.json().status, 'completed');
  assert.equal(JSON.stringify(finished.json()).includes('Nila'), false);
  assert.equal(JSON.stringify(finished.json()).includes('http'), false);
  const job = await prisma.jobOutbox.findUniqueOrThrow({ where: { jobId: accepted.json().jobId } });
  const result = job.result as { delivery: string; profiles: Array<{ nickname: string }> };
  assert.equal(result.delivery, 'database-job-row-only');
  assert.equal(result.profiles[0]?.nickname, 'Nila');
});
