import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { parse as parseYaml } from 'yaml';
import { canonicalJson } from '../src/canonical.js';
import { monthsForBand } from '../src/modules/content/age-band.js';
import { eventBatchSchema, profileCreateSchema } from '../src/modules/profiles/schemas.js';
import { lessonDocumentSchema } from '../src/schemas/lesson.js';
import { defaultFixtureDir, defaultSchemaPath } from '../src/seed.js';

const here = path.dirname(fileURLToPath(import.meta.url));

test('canonical json sorts keys and hashes the fixture', () => {
  assert.equal(canonicalJson({ b: 1, a: 'hi' }), '{"a":"hi","b":1}');
  const lesson = JSON.parse(
    readFileSync(path.join(defaultFixtureDir(), 'animal.elephant.001.json'), 'utf8'),
  );
  const checksums = JSON.parse(
    readFileSync(path.join(defaultFixtureDir(), 'checksums.json'), 'utf8'),
  ) as { payloadSha256: string };
  const hash = createHash('sha256').update(canonicalJson(lesson)).digest('hex');
  assert.equal(hash, checksums.payloadSha256);
});

test('zod accepts the elephant lesson and rejects hostile documents', () => {
  const lesson = JSON.parse(
    readFileSync(path.join(defaultFixtureDir(), 'animal.elephant.001.json'), 'utf8'),
  );
  assert.equal(lessonDocumentSchema.safeParse(lesson).success, true);
  const scripted = { ...lesson, interaction: { ...lesson.interaction, type: 'script' } };
  assert.equal(lessonDocumentSchema.safeParse(scripted).success, false);
  const extra = { ...lesson, html: '<b>no</b>' };
  assert.equal(lessonDocumentSchema.safeParse(extra).success, false);
  const future = { ...lesson, schemaVersion: '9.0' };
  assert.equal(lessonDocumentSchema.safeParse(future).success, false);
  const schema = JSON.parse(readFileSync(defaultSchemaPath(), 'utf8')) as { $schema: string };
  assert.match(schema.$schema, /2020-12/);
});

test('age bands overlap on the shared boundary month', () => {
  assert.deepEqual(monthsForBand('1-2'), [12, 24]);
  assert.deepEqual(monthsForBand('2-3'), [24, 36]);
  assert.deepEqual(monthsForBand('4-5'), [48, 60]);
});

test('phase 5 profile schemas are documented and not routed', () => {
  const openapi = parseYaml(readFileSync(path.join(here, '../openapi/openapi.yaml'), 'utf8')) as {
    paths: Record<string, Record<string, { operationId?: string }>>;
  };
  const ids = Object.values(openapi.paths).flatMap((pathItem) =>
    Object.values(pathItem)
      .map((operation) => operation.operationId)
      .filter((id): id is string => Boolean(id)),
  );
  for (const id of [
    'getHealth',
    'getReady',
    'getContentManifest',
    'getContentVersionPointer',
    'getLessonDocument',
    'getAssetDescriptor',
    'createProfile',
    'syncEvents',
  ]) {
    assert.ok(ids.includes(id), id);
  }
  assert.equal(
    profileCreateSchema.safeParse({
      clientProfileId: '11111111-1111-4111-8111-111111111111',
      nickname: 'Asha',
      avatarId: 'leaf',
      ageBand: '2-3',
      preferredLocale: 'ta',
      bilingualMode: true,
    }).success,
    true,
  );
  assert.equal(
    eventBatchSchema.safeParse({
      events: [
        {
          eventId: '22222222-2222-4222-8222-222222222222',
          contentId: 'animal.elephant.001',
          contentVersion: 1,
          eventType: 'completed',
          occurredAt: '2026-10-29T12:00:00.000Z',
          durationBucket: 'lt_1m',
        },
      ],
    }).success,
    true,
  );
  const routes = readFileSync(path.join(here, '../src/modules/content/routes.ts'), 'utf8');
  assert.equal(routes.includes('child_profile'), false);
  assert.equal(routes.includes('nickname'), false);
  assert.equal(routes.includes('/profiles'), false);
});
