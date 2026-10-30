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
import {
  assertReviewedFixtureFile,
  defaultFixtureDir,
  defaultSchemaPath,
  FixturePublishClosedError,
  reviewedFixtureFiles,
} from '../src/seed.js';

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

test('zod accepts each activity sample and rejects a label that drops a locale', () => {
  const files = [
    'color.red.001.json',
    'pair.daynight.001.json',
    'sort.bigsmall.001.json',
    'count.birds.001.json',
    'order.morning.001.json',
  ];
  for (const file of files) {
    const lesson = JSON.parse(readFileSync(path.join(defaultFixtureDir(), file), 'utf8'));
    assert.equal(lessonDocumentSchema.safeParse(lesson).success, true, file);
  }
  const red = JSON.parse(
    readFileSync(path.join(defaultFixtureDir(), 'color.red.001.json'), 'utf8'),
  ) as {
    interaction: { choices: Array<{ label: Record<string, string> }> };
    localizations: { en: { feedbackRetry?: string } };
  };
  const choice = red.interaction.choices[0];
  assert.ok(choice);
  delete choice.label.ta;
  assert.equal(lessonDocumentSchema.safeParse(red).success, false);
  choice.label.ta = 'சிவப்பு';
  delete red.localizations.en.feedbackRetry;
  assert.equal(lessonDocumentSchema.safeParse(red).success, false);
});

test('age bands overlap on the shared boundary month', () => {
  assert.deepEqual(monthsForBand('1-2'), [12, 24]);
  assert.deepEqual(monthsForBand('2-3'), [24, 36]);
  assert.deepEqual(monthsForBand('4-5'), [48, 60]);
});

test('a new lesson cannot be published through the fixture path', () => {
  assert.throws(
    () => assertReviewedFixtureFile('shape.circle.001.json'),
    FixturePublishClosedError,
  );
  assert.deepEqual(reviewedFixtureFiles, [
    'animal.elephant.001.json',
    'color.red.001.json',
    'pair.daynight.001.json',
    'sort.bigsmall.001.json',
    'count.birds.001.json',
    'order.morning.001.json',
  ]);
  for (const fileName of reviewedFixtureFiles) {
    assert.doesNotThrow(() => assertReviewedFixtureFile(fileName));
  }
});

test('phase 5 profile schemas are documented and routed outside content', () => {
  const openapi = parseYaml(readFileSync(path.join(here, '../openapi/openapi.yaml'), 'utf8')) as {
    paths: Record<string, Record<string, { operationId?: string }>>;
  };
  assert.equal(
    Object.keys(openapi.paths).some((item) => item.startsWith('/admin')),
    false,
  );
  const ids = Object.values(openapi.paths).flatMap((pathItem) =>
    Object.values(pathItem)
      .map((operation) => operation.operationId)
      .filter((id): id is string => Boolean(id)),
  );
  for (const id of [
    'getHealth',
    'getReady',
    'getContentManifest',
    'getContentPack',
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
  const accounts = readFileSync(path.join(here, '../src/modules/accounts/routes.ts'), 'utf8');
  assert.equal(accounts.includes('/profiles'), true);
  assert.equal(accounts.includes('/privacy/delete-account'), true);
});
