import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { PrismaClient } from '@prisma/client';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import type { AppConfig } from '../src/config.js';
import {
  packChecksum,
  publishNextPackVersion,
  rollbackPublishedPack,
} from '../src/modules/content/packs.js';
import { defaultFixtureDir, defaultSchemaPath, seedDatabase } from '../src/seed.js';

const prisma = new PrismaClient();
let app: FastifyInstance;

const config: AppConfig = {
  assetSigningKey: 'test-signing-key',
  publicBaseUrl: 'http://127.0.0.1:3000',
  fixtureDir: defaultFixtureDir(),
  schemaPath: defaultSchemaPath(),
  rateManifest: 60,
  rateLesson: 120,
  rateAsset: 120,
  rateAdmin: 60,
  identityProvider: 'deny',
  assetUrlTtlSeconds: 300,
  host: '127.0.0.1',
  port: 3000,
};

before(async () => {
  await seedDatabase(prisma, config.fixtureDir, config.schemaPath);
  app = await buildApp({ prisma, config, logger: false });
});

after(async () => {
  await app.close();
  await prisma.$disconnect();
});

test('health does not require auth and echoes a safe request id', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/api/v1/health',
    headers: { 'x-request-id': 'abc-123' },
  });
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { status: 'ok' });
  assert.equal(response.headers['x-request-id'], 'abc-123');
  assert.equal(response.headers['set-cookie'], undefined);
});

test('ready checks the database', async () => {
  const response = await app.inject({ method: 'GET', url: '/api/v1/health/ready' });
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { status: 'ok' });
});

test('ready returns 503 when the database check fails', async () => {
  const broken = await buildApp({
    prisma,
    config,
    logger: false,
    ready: async () => {
      throw new Error('down');
    },
  });
  const response = await broken.inject({ method: 'GET', url: '/api/v1/health/ready' });
  assert.equal(response.statusCode, 503);
  const body = response.json() as {
    error: { code: string; retryable: boolean; requestId: string };
  };
  assert.equal(body.error.code, 'INTERNAL');
  assert.equal(body.error.retryable, true);
  assert.ok(body.error.requestId);
  await broken.close();
});

test('manifest returns the elephant lesson for each locale and band', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/api/v1/content/manifest?locale=hi&ageBand=1-2',
  });
  assert.equal(response.statusCode, 200);
  assert.match(String(response.headers['cache-control']), /public/);
  assert.match(String(response.headers.etag), /^"[a-f0-9]{64}"$/);
  const body = response.json() as {
    locale: string;
    ageBand: string;
    nextCursor: null;
    items: Array<{
      title: string;
      interactionType: string;
      payloadSha256: string;
      contentId: string;
      packId: string;
    }>;
  };
  assert.equal(body.locale, 'hi');
  assert.equal(body.ageBand, '1-2');
  assert.equal(body.nextCursor, null);
  assert.equal(body.items.length, 2);
  assert.equal(body.items[0]?.title, 'हाथी');
  assert.equal(body.items[0]?.interactionType, 'tap_to_learn');
  assert.equal(body.items[0]?.contentId, 'animal.elephant.001');
  assert.equal(body.items[1]?.contentId, 'color.red.001');
  assert.equal(body.items[1]?.title, 'लाल');
  assert.equal(body.items[1]?.interactionType, 'single_choice');
  assert.equal(body.items[0]?.packId, 'pack.catalog.001');
  assert.equal(body.items[1]?.packId, 'pack.catalog.001');
  const rawHash = createHash('sha256').update(response.body).digest('hex');
  assert.equal(`"${rawHash}"`, response.headers.etag);
});

test('manifest age band 4-5 keeps counting and sequencing only', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/api/v1/content/manifest?locale=en&ageBand=4-5',
  });
  assert.equal(response.statusCode, 200);
  const body = response.json() as { items: Array<{ contentId: string }> };
  assert.deepEqual(
    body.items.map((item) => item.contentId),
    ['animal.elephant.001', 'count.birds.001', 'order.morning.001'],
  );
});

test('the catalog pack checksum matches its pins and a bad checksum is rejected', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/api/v1/content/packs/pack.catalog.001',
  });
  assert.equal(response.statusCode, 200);
  const body = response.json() as {
    packId: string;
    packVersion: number;
    checksumSha256: string;
    totalBytes: number;
    items: Array<{
      position: number;
      contentId: string;
      contentVersion: number;
      payloadSha256: string;
    }>;
  };
  assert.equal(body.packId, 'pack.catalog.001');
  assert.equal(body.totalBytes > 0, true);
  assert.deepEqual(
    body.items.map((item) => item.contentId),
    [
      'animal.elephant.001',
      'color.red.001',
      'count.birds.001',
      'order.morning.001',
      'pair.daynight.001',
      'sort.bigsmall.001',
    ],
  );
  assert.equal(
    body.checksumSha256,
    packChecksum(
      body.items.map((item) => ({
        contentId: item.contentId,
        contentVersion: item.contentVersion,
      })),
    ),
  );
  const missing = await app.inject({ method: 'GET', url: '/api/v1/content/packs/pack.missing' });
  assert.equal(missing.statusCode, 404);
  assert.equal(missing.json().error.code, 'CONTENT_NOT_FOUND');

  const row = await prisma.contentPack.findFirstOrThrow({
    where: { packId: 'pack.catalog.001', status: 'published' },
  });
  await prisma.contentPack.update({
    where: { packId_packVersion: { packId: row.packId, packVersion: row.packVersion } },
    data: { checksumSha256: '0'.repeat(64) },
  });
  try {
    const bad = await app.inject({ method: 'GET', url: '/api/v1/content/packs/pack.catalog.001' });
    assert.equal(bad.statusCode, 500);
    assert.equal(bad.json().error.code, 'INTERNAL');
    assert.equal(bad.json().error.retryable, true);
    assert.equal('items' in bad.json(), false);
  } finally {
    await prisma.contentPack.update({
      where: { packId_packVersion: { packId: row.packId, packVersion: row.packVersion } },
      data: { checksumSha256: row.checksumSha256 },
    });
  }
});

test('rollback restores the last published pack and leaves lesson bytes alone', async () => {
  const before = await app.inject({ method: 'GET', url: '/api/v1/content/packs/pack.catalog.001' });
  const published = before.json() as {
    packVersion: number;
    totalBytes: number;
    items: Array<{ contentId: string; contentVersion: number; payloadSha256: string }>;
  };
  const elephantBefore = await prisma.contentVersion.findUniqueOrThrow({
    where: { contentId_contentVersion: { contentId: 'animal.elephant.001', contentVersion: 1 } },
  });
  const next = await publishNextPackVersion(
    prisma,
    'pack.catalog.001',
    published.items.map((item) => ({
      contentId: item.contentId,
      contentVersion: item.contentVersion,
    })),
    published.totalBytes,
  );
  try {
    const during = await app.inject({
      method: 'GET',
      url: '/api/v1/content/packs/pack.catalog.001',
    });
    assert.equal(during.statusCode, 200);
    assert.equal(during.json().packVersion, next);
    assert.equal(await rollbackPublishedPack(prisma, 'pack.catalog.001'), published.packVersion);
    const after = await app.inject({
      method: 'GET',
      url: '/api/v1/content/packs/pack.catalog.001',
    });
    assert.equal(after.json().packVersion, published.packVersion);
    assert.deepEqual(
      after.json().items.map((item: { contentId: string }) => item.contentId),
      published.items.map((item) => item.contentId),
    );
    const elephantAfter = await prisma.contentVersion.findUniqueOrThrow({
      where: { contentId_contentVersion: { contentId: 'animal.elephant.001', contentVersion: 1 } },
    });
    assert.equal(elephantAfter.payloadSha256, elephantBefore.payloadSha256);
    assert.equal(elephantAfter.status, 'published');
  } finally {
    const current = await prisma.contentPack.findFirst({
      where: { packId: 'pack.catalog.001', status: 'published' },
    });
    if (current && current.packVersion !== published.packVersion) {
      await rollbackPublishedPack(prisma, 'pack.catalog.001');
    }
  }
});

test('manifest rejects a missing or unknown locale', async () => {
  const missing = await app.inject({ method: 'GET', url: '/api/v1/content/manifest?ageBand=2-3' });
  assert.equal(missing.statusCode, 400);
  assert.equal(missing.json().error.code, 'VALIDATION_ERROR');
  assert.equal(missing.json().error.retryable, false);
  const bad = await app.inject({
    method: 'GET',
    url: '/api/v1/content/manifest?locale=zz&ageBand=2-3',
  });
  assert.equal(bad.statusCode, 400);
});

test('pointer has no lesson body and unknown ids are not found', async () => {
  const response = await app.inject({ method: 'GET', url: '/api/v1/content/animal.elephant.001' });
  assert.equal(response.statusCode, 200);
  const body = response.json() as Record<string, unknown>;
  assert.equal(body.contentVersion, 1);
  assert.equal(typeof body.payloadSha256, 'string');
  assert.equal('localizations' in body, false);
  assert.equal('assets' in body, false);
  const missing = await app.inject({ method: 'GET', url: '/api/v1/content/missing.lesson' });
  assert.equal(missing.statusCode, 404);
  assert.equal(missing.json().error.code, 'CONTENT_NOT_FOUND');
  assert.equal(missing.json().error.retryable, false);
});

test('lesson document bytes match the stored sha256 and contain no url field', async () => {
  const response = await app.inject({
    method: 'GET',
    url: '/api/v1/content/animal.elephant.001/versions/1',
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.headers['cache-control'], 'public, max-age=31536000, immutable');
  const hash = createHash('sha256').update(response.body).digest('hex');
  assert.equal(response.headers.etag, `"${hash}"`);
  const document = response.json() as {
    schemaVersion: string;
    assets: Array<{ sha256: string }>;
    interaction: { type: string };
  };
  assert.equal(document.schemaVersion, '1.0');
  assert.equal(document.interaction.type, 'tap_to_learn');
  assert.equal(document.assets.length, 4);
  assertNoForbiddenKeys(document);
  const checksums = JSON.parse(readFileSync(`${config.fixtureDir}/checksums.json`, 'utf8')) as {
    payloadSha256: string;
  };
  assert.equal(hash, checksums.payloadSha256);
});

test('an unpublished version is retryable and a bad version is a validation error', async () => {
  const source = await prisma.contentVersion.findUniqueOrThrow({
    where: { contentId_contentVersion: { contentId: 'animal.elephant.001', contentVersion: 1 } },
  });
  await prisma.contentVersion.create({
    data: {
      contentId: source.contentId,
      contentVersion: 2,
      schemaVersion: source.schemaVersion,
      categoryId: source.categoryId,
      ageMinMonths: source.ageMinMonths,
      ageMaxMonths: source.ageMaxMonths,
      interactionType: source.interactionType,
      status: 'unpublished',
      payload: source.payload as object,
      payloadSha256: source.payloadSha256,
    },
  });
  try {
    const unpublished = await app.inject({
      method: 'GET',
      url: '/api/v1/content/animal.elephant.001/versions/2',
    });
    assert.equal(unpublished.statusCode, 404);
    assert.equal(unpublished.json().error.code, 'CONTENT_VERSION_UNAVAILABLE');
    assert.equal(unpublished.json().error.retryable, true);
  } finally {
    await prisma.contentVersion.delete({
      where: { contentId_contentVersion: { contentId: 'animal.elephant.001', contentVersion: 2 } },
    });
  }
  const bad = await app.inject({
    method: 'GET',
    url: '/api/v1/content/animal.elephant.001/versions/0',
  });
  assert.equal(bad.statusCode, 400);
  assert.equal(bad.json().error.code, 'VALIDATION_ERROR');
  const missing = await app.inject({
    method: 'GET',
    url: '/api/v1/content/missing.lesson/versions/1',
  });
  assert.equal(missing.statusCode, 404);
  assert.equal(missing.json().error.code, 'CONTENT_NOT_FOUND');
});

test('asset descriptor is unauthenticated and the signed bytes match the checksum', async () => {
  const response = await app.inject({ method: 'GET', url: '/api/v1/assets/img.elephant.001' });
  assert.equal(response.statusCode, 200);
  assert.equal(response.headers.authorization, undefined);
  const body = response.json() as {
    sha256: string;
    byteSize: number;
    url: string;
    urlExpiresAt: string;
    mediaType: string;
  };
  assert.equal(body.mediaType, 'image');
  assert.equal(body.byteSize, 297008);
  assert.ok(body.url.includes('/api/v1/assets/img.elephant.001/bytes'));
  assert.ok(!Number.isNaN(Date.parse(body.urlExpiresAt)));
  const url = new URL(body.url);
  const bytes = await app.inject({
    method: 'GET',
    url: `${url.pathname}${url.search}`,
  });
  assert.equal(bytes.statusCode, 200);
  assert.equal(bytes.headers['content-type'], 'image/png');
  const hash = createHash('sha256').update(bytes.rawPayload).digest('hex');
  assert.equal(hash, body.sha256);
  const missing = await app.inject({ method: 'GET', url: '/api/v1/assets/missing.asset' });
  assert.equal(missing.statusCode, 404);
  assert.equal(missing.json().error.code, 'ASSET_NOT_FOUND');
});

test('published content is rate limited', async () => {
  const limited = await buildApp({
    prisma,
    config: { ...config, rateManifest: 2 },
    logger: false,
  });
  const first = await limited.inject({
    method: 'GET',
    url: '/api/v1/content/manifest?locale=en&ageBand=3-4',
  });
  const second = await limited.inject({
    method: 'GET',
    url: '/api/v1/content/manifest?locale=en&ageBand=3-4',
  });
  const third = await limited.inject({
    method: 'GET',
    url: '/api/v1/content/manifest?locale=en&ageBand=3-4',
  });
  assert.equal(first.statusCode, 200);
  assert.equal(second.statusCode, 200);
  assert.equal(third.statusCode, 429);
  assert.equal(third.json().error.code, 'RATE_LIMITED');
  assert.equal(third.json().error.retryable, true);
  assert.ok(third.headers['retry-after']);
  await limited.close();
});

test('parent account routes are not mounted', async () => {
  const response = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: { 'content-type': 'application/json' },
    payload: {},
  });
  assert.equal(response.statusCode, 404);
  assert.notEqual(response.statusCode, 201);
});

test('a published payload cannot be updated', async () => {
  await assert.rejects(
    () =>
      prisma.$executeRaw`
        UPDATE content_versions
        SET payload = '{"schemaVersion":"1.0"}'::jsonb
        WHERE content_id = 'animal.elephant.001' AND content_version = 1
      `,
    /immutable/,
  );
});

function assertNoForbiddenKeys(value: unknown): void {
  if (Array.isArray(value)) {
    value.forEach(assertNoForbiddenKeys);
    return;
  }
  if (!value || typeof value !== 'object') return;
  for (const [key, child] of Object.entries(value)) {
    assert.equal(['url', 'script', 'html', 'component', 'widget', 'code'].includes(key), false);
    assertNoForbiddenKeys(child);
  }
}
