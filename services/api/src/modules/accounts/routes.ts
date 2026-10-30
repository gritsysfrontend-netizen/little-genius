import { Readable } from 'node:stream';
import type { Prisma, PrismaClient } from '@prisma/client';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { sha256Hex } from '../../canonical.js';
import type { AppConfig } from '../../config.js';
import { sendError } from '../../errors.js';
import type { AccessClaims, IdentityProvider } from '../admin/identity.js';
import { eventBatchSchema, profileCreateSchema, profilePatchSchema } from '../profiles/schemas.js';

const uuidV4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const profileMissing = 'That profile was not found.';
const requestMissing = 'That request was not found.';

const consentSchema = z
  .object({
    purpose: z.literal('account_sync'),
    noticeVersion: z.literal('account-sync-1'),
    decision: z.literal('granted'),
  })
  .strict();

type ParentAccount = {
  id: string;
  authProviderSub: string;
  consentStatus: string;
  deletedAt: Date | null;
  sessionsRevokedAt: Date | null;
};

declare module 'fastify' {
  interface FastifyRequest {
    parentClaims?: AccessClaims;
    parentAccount?: ParentAccount;
    rawBody?: Buffer;
  }
}

function isUuidV4(value: string): boolean {
  return uuidV4.test(value);
}

function cleanNickname(value: string): string | null {
  const stripped = value.replace(/[\u0000-\u001F\u007F]/g, '').trim();
  const length = [...stripped].length;
  if (length < 1 || length > 24) return null;
  return stripped;
}

function profileJson(row: {
  id: string;
  nickname: string;
  avatarId: string;
  ageBand: string;
  preferredLocale: string;
  bilingualMode: boolean;
  revision: number;
}) {
  return {
    profileId: row.id,
    nickname: row.nickname,
    avatarId: row.avatarId,
    ageBand: row.ageBand,
    preferredLocale: row.preferredLocale,
    bilingualMode: row.bilingualMode,
    revision: row.revision,
  };
}

function jobJson(row: { jobId: string; jobType: string; status: string }) {
  return { jobId: row.jobId, jobType: row.jobType, status: row.status };
}

function isPrivacyStatusRead(request: FastifyRequest): boolean {
  const path = request.url.split('?')[0] ?? '';
  return request.method === 'GET' && /\/privacy\/requests\/[^/]+$/.test(path);
}

async function accountFor(prisma: PrismaClient, sub: string): Promise<ParentAccount> {
  const existing = await prisma.parentAccount.findUnique({ where: { authProviderSub: sub } });
  if (existing) return existing;
  try {
    return await prisma.parentAccount.create({
      data: { authProviderSub: sub, consentStatus: 'none' },
    });
  } catch {
    const again = await prisma.parentAccount.findUnique({ where: { authProviderSub: sub } });
    if (again) return again;
    throw new Error('account was not created');
  }
}

function idempotencyKeyOf(request: FastifyRequest): string | null {
  const raw = request.headers['idempotency-key'];
  if (typeof raw !== 'string' || !isUuidV4(raw)) return null;
  return raw.toLowerCase();
}

function requireKey(request: FastifyRequest, reply: FastifyReply): string | null {
  const key = idempotencyKeyOf(request);
  if (!key) {
    void sendError(reply, 400, 'VALIDATION_ERROR', 'Idempotency-Key must be a UUID.', false);
    return null;
  }
  return key;
}

function bodyHash(request: FastifyRequest): string {
  return sha256Hex(request.rawBody ?? Buffer.alloc(0));
}

async function ownedProfile(prisma: PrismaClient, accountId: string, profileId: string) {
  if (!isUuidV4(profileId)) return null;
  return prisma.childProfile.findFirst({
    where: { id: profileId, parentAccountId: accountId, deletedAt: null },
  });
}

export function registerAccountRoutes(
  app: FastifyInstance,
  prisma: PrismaClient,
  config: AppConfig,
  identity: IdentityProvider,
): void {
  app.addHook('preParsing', async (request, _reply, payload) => {
    if (request.method === 'GET' || request.method === 'HEAD' || request.method === 'OPTIONS') {
      return payload;
    }
    const chunks: Buffer[] = [];
    for await (const chunk of payload) {
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    const raw = Buffer.concat(chunks);
    request.rawBody = raw;
    return Readable.from(raw);
  });

  app.addHook('onRequest', async (request, reply) => {
    const claims = identity.verify(request.headers.authorization);
    if (!claims || claims.aud !== 'parent') {
      await sendError(reply, 401, 'UNAUTHENTICATED', 'Parent sign-in is required.', false);
      return;
    }
    const account = await accountFor(prisma, claims.sub);
    request.parentClaims = claims;
    request.parentAccount = account;
    if ((account.sessionsRevokedAt || account.deletedAt) && !isPrivacyStatusRead(request)) {
      await sendError(reply, 401, 'UNAUTHENTICATED', 'This session was revoked.', false);
      return;
    }
  });

  app.get('/profiles', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const rows = await prisma.childProfile.findMany({
      where: { parentAccountId: account.id, deletedAt: null },
      orderBy: { id: 'asc' },
    });
    return reply.send({ profiles: rows.map(profileJson) });
  });

  app.post('/profiles', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const key = requireKey(request, reply);
    if (!key) return;
    if (account.consentStatus !== 'granted') {
      return sendError(
        reply,
        403,
        'FORBIDDEN',
        'Consent is required before the first upload.',
        false,
      );
    }
    const parsed = profileCreateSchema.safeParse(request.body);
    if (!parsed.success || !isUuidV4(parsed.data.clientProfileId)) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
    }
    const nickname = cleanNickname(parsed.data.nickname);
    if (!nickname) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
    }
    const hash = bodyHash(request);
    const input = { ...parsed.data, nickname };
    const outcome = await prisma.$transaction(async (tx) => {
      const existingKey = await tx.idempotencyKey.findUnique({
        where: { parentAccountId_key: { parentAccountId: account.id, key } },
      });
      if (existingKey) {
        if (existingKey.requestSha256 !== hash) return { kind: 'reuse' as const };
        return {
          kind: 'replay' as const,
          status: existingKey.statusCode,
          body: existingKey.responseBody,
        };
      }
      const existingProfile = await tx.childProfile.findUnique({
        where: { id: input.clientProfileId },
      });
      if (
        existingProfile &&
        (existingProfile.parentAccountId !== account.id || existingProfile.deletedAt)
      ) {
        return { kind: 'conflict' as const };
      }
      const row =
        existingProfile ??
        (await tx.childProfile.create({
          data: {
            id: input.clientProfileId,
            parentAccountId: account.id,
            nickname: input.nickname,
            avatarId: input.avatarId,
            ageBand: input.ageBand,
            preferredLocale: input.preferredLocale,
            bilingualMode: input.bilingualMode,
            revision: 1,
          },
        }));
      const status = existingProfile ? 200 : 201;
      const body = profileJson(row);
      await tx.idempotencyKey.create({
        data: {
          parentAccountId: account.id,
          key,
          requestSha256: hash,
          statusCode: status,
          responseBody: body,
        },
      });
      return { kind: 'done' as const, status, body };
    });
    if (outcome.kind === 'reuse') {
      return sendError(
        reply,
        409,
        'IDEMPOTENCY_KEY_REUSE',
        'That idempotency key was already used.',
        false,
      );
    }
    if (outcome.kind === 'conflict') {
      return sendError(reply, 409, 'PROFILE_ID_CONFLICT', 'That profile id cannot be used.', false);
    }
    return reply.code(outcome.status).send(outcome.body);
  });

  app.patch('/profiles/:profileId', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    if (account.consentStatus !== 'granted') {
      return sendError(
        reply,
        403,
        'FORBIDDEN',
        'Consent is required before the first upload.',
        false,
      );
    }
    const profileId = (request.params as { profileId: string }).profileId;
    const profile = await ownedProfile(prisma, account.id, profileId);
    if (!profile) return sendError(reply, 404, 'PROFILE_NOT_FOUND', profileMissing, false);
    const header = request.headers['if-match'];
    const match = typeof header === 'string' ? /^"(\d+)"$/.exec(header) : null;
    if (!match?.[1]) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'If-Match must quote the revision.', false);
    }
    if (profile.revision !== Number(match[1])) {
      return sendError(
        reply,
        409,
        'REVISION_CONFLICT',
        'The profile changed. Refresh it and try again.',
        false,
      );
    }
    const parsed = profilePatchSchema.safeParse(request.body);
    if (!parsed.success) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
    }
    const data: Prisma.ChildProfileUpdateInput = { revision: profile.revision + 1 };
    if (parsed.data.nickname !== undefined) {
      const nickname = cleanNickname(parsed.data.nickname);
      if (!nickname)
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
      data.nickname = nickname;
    }
    if (parsed.data.avatarId !== undefined) data.avatarId = parsed.data.avatarId;
    if (parsed.data.ageBand !== undefined) data.ageBand = parsed.data.ageBand;
    if (parsed.data.preferredLocale !== undefined)
      data.preferredLocale = parsed.data.preferredLocale;
    if (parsed.data.bilingualMode !== undefined) data.bilingualMode = parsed.data.bilingualMode;
    const updated = await prisma.childProfile.update({ where: { id: profile.id }, data });
    return reply.send(profileJson(updated));
  });

  app.delete('/profiles/:profileId', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const key = requireKey(request, reply);
    if (!key) return;
    const hash = bodyHash(request);
    const profileId = (request.params as { profileId: string }).profileId;
    const outcome = await prisma.$transaction(async (tx) => {
      const existingKey = await tx.idempotencyKey.findUnique({
        where: { parentAccountId_key: { parentAccountId: account.id, key } },
      });
      if (existingKey) {
        if (existingKey.requestSha256 !== hash) return { kind: 'reuse' as const };
        return {
          kind: 'replay' as const,
          status: existingKey.statusCode,
          body: existingKey.responseBody,
        };
      }
      const profile = isUuidV4(profileId)
        ? await tx.childProfile.findFirst({
            where: { id: profileId, parentAccountId: account.id, deletedAt: null },
          })
        : null;
      if (!profile) return { kind: 'missing' as const };
      await tx.learningEvent.deleteMany({ where: { profileId: profile.id } });
      await tx.progressSummary.deleteMany({ where: { profileId: profile.id } });
      await tx.childProfile.update({
        where: { id: profile.id },
        data: { deletedAt: new Date(), nickname: '' },
      });
      const body = { status: 'deleted' };
      await tx.idempotencyKey.create({
        data: {
          parentAccountId: account.id,
          key,
          requestSha256: hash,
          statusCode: 202,
          responseBody: body,
        },
      });
      return { kind: 'done' as const, status: 202, body };
    });
    if (outcome.kind === 'reuse') {
      return sendError(
        reply,
        409,
        'IDEMPOTENCY_KEY_REUSE',
        'That idempotency key was already used.',
        false,
      );
    }
    if (outcome.kind === 'missing') {
      return sendError(reply, 404, 'PROFILE_NOT_FOUND', profileMissing, false);
    }
    return reply.code(outcome.status).send(outcome.body);
  });

  app.post(
    '/profiles/:profileId/events::batch',
    {
      bodyLimit: 65_536,
      config: {
        rateLimit: {
          max: config.rateEvents,
          timeWindow: '1 minute',
          keyGenerator: (request: FastifyRequest) => request.parentAccount?.id ?? request.ip,
        },
      },
    },
    async (request, reply) => {
      const account = request.parentAccount;
      if (!account) return;
      const key = requireKey(request, reply);
      if (!key) return;
      if (account.consentStatus !== 'granted') {
        return sendError(
          reply,
          403,
          'FORBIDDEN',
          'Consent is required before the first upload.',
          false,
        );
      }
      const profileId = (request.params as { profileId: string }).profileId;
      const profile = await ownedProfile(prisma, account.id, profileId);
      if (!profile) return sendError(reply, 404, 'PROFILE_NOT_FOUND', profileMissing, false);
      const container = z
        .object({ events: z.array(z.unknown()) })
        .strict()
        .safeParse(request.body);
      if (!container.success) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
      }
      if (container.data.events.length > 50) {
        return sendError(reply, 413, 'PAYLOAD_TOO_LARGE', 'The batch is too large.', false);
      }
      const parsed = eventBatchSchema.safeParse(request.body);
      if (!parsed.success || parsed.data.events.some((event) => !isUuidV4(event.eventId))) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
      }
      const hash = bodyHash(request);
      const categories = new Map<string, string>();
      for (const event of parsed.data.events) {
        const mapKey = `${event.contentId}:${event.contentVersion}`;
        if (categories.has(mapKey)) continue;
        const version = await prisma.contentVersion.findUnique({
          where: {
            contentId_contentVersion: {
              contentId: event.contentId,
              contentVersion: event.contentVersion,
            },
          },
          select: { categoryId: true },
        });
        categories.set(mapKey, version?.categoryId ?? 'unlisted');
      }
      const outcome = await prisma.$transaction(async (tx) => {
        const existingKey = await tx.idempotencyKey.findUnique({
          where: { parentAccountId_key: { parentAccountId: account.id, key } },
        });
        if (existingKey) {
          if (existingKey.requestSha256 !== hash) return { kind: 'reuse' as const };
          return {
            kind: 'replay' as const,
            status: existingKey.statusCode,
            body: existingKey.responseBody,
          };
        }
        const applied: string[] = [];
        const duplicates: string[] = [];
        const seen = new Set<string>();
        for (const event of parsed.data.events) {
          if (seen.has(event.eventId)) {
            duplicates.push(event.eventId);
            continue;
          }
          seen.add(event.eventId);
          const existing = await tx.learningEvent.findUnique({ where: { eventId: event.eventId } });
          if (existing) {
            if (existing.profileId !== profile.id) return { kind: 'event-conflict' as const };
            duplicates.push(event.eventId);
            continue;
          }
          await tx.learningEvent.create({
            data: {
              eventId: event.eventId,
              profileId: profile.id,
              contentId: event.contentId,
              contentVersion: event.contentVersion,
              eventType: event.eventType,
              durationBucket: event.durationBucket ?? null,
              occurredAt: new Date(event.occurredAt),
            },
          });
          const categoryId =
            categories.get(`${event.contentId}:${event.contentVersion}`) ?? 'unlisted';
          const summary = await tx.progressSummary.findUnique({
            where: { profileId_categoryId: { profileId: profile.id, categoryId } },
          });
          const occurredAt = new Date(event.occurredAt);
          if (!summary) {
            await tx.progressSummary.create({
              data: {
                profileId: profile.id,
                categoryId,
                startedCount: event.eventType === 'started' ? 1 : 0,
                completedCount: event.eventType === 'completed' ? 1 : 0,
                lastActivityAt: occurredAt,
              },
            });
          } else {
            const previous = summary.lastActivityAt ?? new Date(0);
            await tx.progressSummary.update({
              where: { profileId_categoryId: { profileId: profile.id, categoryId } },
              data: {
                startedCount: summary.startedCount + (event.eventType === 'started' ? 1 : 0),
                completedCount: summary.completedCount + (event.eventType === 'completed' ? 1 : 0),
                lastActivityAt: occurredAt > previous ? occurredAt : summary.lastActivityAt,
              },
            });
          }
          applied.push(event.eventId);
        }
        const body = { applied, duplicates };
        await tx.idempotencyKey.create({
          data: {
            parentAccountId: account.id,
            key,
            requestSha256: hash,
            statusCode: 200,
            responseBody: body,
          },
        });
        return { kind: 'done' as const, status: 200, body };
      });
      if (outcome.kind === 'reuse') {
        return sendError(
          reply,
          409,
          'IDEMPOTENCY_KEY_REUSE',
          'That idempotency key was already used.',
          false,
        );
      }
      if (outcome.kind === 'event-conflict') {
        return sendError(reply, 409, 'VALIDATION_ERROR', 'That event id cannot be used.', false);
      }
      return reply.code(outcome.status).send(outcome.body);
    },
  );

  app.get('/profiles/:profileId/progress', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const profileId = (request.params as { profileId: string }).profileId;
    const profile = await ownedProfile(prisma, account.id, profileId);
    if (!profile) return sendError(reply, 404, 'PROFILE_NOT_FOUND', profileMissing, false);
    const rows = await prisma.progressSummary.findMany({
      where: { profileId: profile.id },
      orderBy: { categoryId: 'asc' },
    });
    return reply.send({
      profileId: profile.id,
      categories: rows.map((row) => ({
        categoryId: row.categoryId,
        startedCount: row.startedCount,
        completedCount: row.completedCount,
        lastActivityAt: row.lastActivityAt ? row.lastActivityAt.toISOString() : null,
      })),
    });
  });

  app.post('/privacy/consent', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const key = requireKey(request, reply);
    if (!key) return;
    const parsed = consentSchema.safeParse(request.body);
    if (!parsed.success) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Request is not valid.', false);
    }
    const hash = bodyHash(request);
    const outcome = await prisma.$transaction(async (tx) => {
      const existingKey = await tx.idempotencyKey.findUnique({
        where: { parentAccountId_key: { parentAccountId: account.id, key } },
      });
      if (existingKey) {
        if (existingKey.requestSha256 !== hash) return { kind: 'reuse' as const };
        return {
          kind: 'replay' as const,
          status: existingKey.statusCode,
          body: existingKey.responseBody,
        };
      }
      const record = await tx.consentRecord.create({
        data: {
          parentAccountId: account.id,
          purpose: parsed.data.purpose,
          noticeVersion: parsed.data.noticeVersion,
          decision: parsed.data.decision,
        },
      });
      await tx.parentAccount.update({
        where: { id: account.id },
        data: { consentStatus: 'granted' },
      });
      const body = {
        recordId: record.recordId,
        purpose: record.purpose,
        noticeVersion: record.noticeVersion,
        decision: record.decision,
      };
      await tx.idempotencyKey.create({
        data: {
          parentAccountId: account.id,
          key,
          requestSha256: hash,
          statusCode: 201,
          responseBody: body,
        },
      });
      return { kind: 'done' as const, status: 201, body };
    });
    if (outcome.kind === 'reuse') {
      return sendError(
        reply,
        409,
        'IDEMPOTENCY_KEY_REUSE',
        'That idempotency key was already used.',
        false,
      );
    }
    account.consentStatus = 'granted';
    return reply.code(outcome.status).send(outcome.body);
  });

  app.post('/privacy/export', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const key = requireKey(request, reply);
    if (!key) return;
    if (account.consentStatus !== 'granted') {
      return sendError(
        reply,
        403,
        'FORBIDDEN',
        'Consent is required before the first upload.',
        false,
      );
    }
    const hash = bodyHash(request);
    const outcome = await enqueueJob(prisma, account, key, hash, 'export_account');
    return sendJob(reply, outcome);
  });

  app.post('/privacy/delete-account', async (request, reply) => {
    const account = request.parentAccount;
    const claims = request.parentClaims;
    if (!account || !claims) return;
    if (claims.reauthenticated !== true) {
      return sendError(
        reply,
        401,
        'UNAUTHENTICATED',
        'Sign in again before deleting the account.',
        false,
      );
    }
    const key = requireKey(request, reply);
    if (!key) return;
    const hash = bodyHash(request);
    const outcome = await prisma.$transaction(async (tx) => {
      const existingKey = await tx.idempotencyKey.findUnique({
        where: { parentAccountId_key: { parentAccountId: account.id, key } },
      });
      if (existingKey) {
        if (existingKey.requestSha256 !== hash) return { kind: 'reuse' as const };
        return {
          kind: 'replay' as const,
          status: existingKey.statusCode,
          body: existingKey.responseBody,
        };
      }
      const now = new Date();
      await tx.parentAccount.update({
        where: { id: account.id },
        data: { deletedAt: now, sessionsRevokedAt: now },
      });
      const job = await tx.jobOutbox.create({
        data: {
          parentAccountId: account.id,
          jobType: 'delete_account',
          payload: { parentAccountId: account.id },
          status: 'pending',
        },
      });
      const body = jobJson(job);
      await tx.idempotencyKey.create({
        data: {
          parentAccountId: account.id,
          key,
          requestSha256: hash,
          statusCode: 202,
          responseBody: body,
        },
      });
      return { kind: 'done' as const, status: 202, body };
    });
    return sendJob(reply, outcome);
  });

  app.get('/privacy/requests/:jobId', async (request, reply) => {
    const account = request.parentAccount;
    if (!account) return;
    const jobId = (request.params as { jobId: string }).jobId;
    if (!isUuidV4(jobId)) {
      return sendError(reply, 404, 'PROFILE_NOT_FOUND', requestMissing, false);
    }
    const job = await prisma.jobOutbox.findFirst({
      where: { jobId, parentAccountId: account.id },
    });
    if (!job) return sendError(reply, 404, 'PROFILE_NOT_FOUND', requestMissing, false);
    return reply.send(jobJson(job));
  });
}

type JobOutcome =
  | { kind: 'reuse' }
  | { kind: 'replay'; status: number; body: unknown }
  | { kind: 'done'; status: number; body: { jobId: string; jobType: string; status: string } };

async function enqueueJob(
  prisma: PrismaClient,
  account: ParentAccount,
  key: string,
  hash: string,
  jobType: 'export_account' | 'delete_account',
): Promise<JobOutcome> {
  return prisma.$transaction(async (tx) => {
    const existingKey = await tx.idempotencyKey.findUnique({
      where: { parentAccountId_key: { parentAccountId: account.id, key } },
    });
    if (existingKey) {
      if (existingKey.requestSha256 !== hash) return { kind: 'reuse' as const };
      return {
        kind: 'replay' as const,
        status: existingKey.statusCode,
        body: existingKey.responseBody,
      };
    }
    const job = await tx.jobOutbox.create({
      data: {
        parentAccountId: account.id,
        jobType,
        payload: { parentAccountId: account.id },
        status: 'pending',
      },
    });
    const body = jobJson(job);
    await tx.idempotencyKey.create({
      data: {
        parentAccountId: account.id,
        key,
        requestSha256: hash,
        statusCode: 202,
        responseBody: body,
      },
    });
    return { kind: 'done' as const, status: 202, body };
  });
}

function sendJob(reply: FastifyReply, outcome: JobOutcome) {
  if (outcome.kind === 'reuse') {
    return sendError(
      reply,
      409,
      'IDEMPOTENCY_KEY_REUSE',
      'That idempotency key was already used.',
      false,
    );
  }
  return reply.code(outcome.status).send(outcome.body);
}
