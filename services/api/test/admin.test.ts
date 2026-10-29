import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { after, before, test } from 'node:test';
import { PrismaClient } from '@prisma/client';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import type { AppConfig } from '../src/config.js';
import { TestIdentityProvider, testAuthorization } from '../src/modules/admin/identity.js';
import { inspectUpload } from '../src/modules/admin/uploads.js';
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

const png = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);
const pngSha256 = createHash('sha256').update(png).digest('hex');
const contentId = 'count.stars.001';
const assetId = 'img.stars.001';

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
  await cleanup();
  await app.close();
  await prisma.$disconnect();
});

test('upload inspection allows jpeg png webp mpeg and aac and blocks svg html and javascript', () => {
  assert.equal(inspectUpload(png, 'image/png').ok, true);
  assert.equal(inspectUpload(Buffer.from([0xff, 0xd8, 0xff, 0xd9]), 'image/jpeg').ok, true);
  const webp = Buffer.concat([
    Buffer.from('RIFF'),
    Buffer.from([16, 0, 0, 0]),
    Buffer.from('WEBP'),
    Buffer.alloc(8),
  ]);
  assert.equal(inspectUpload(webp, 'image/webp').ok, true);
  assert.equal(inspectUpload(Buffer.from([0xff, 0xfb, 0x90, 0x00]), 'audio/mpeg').ok, true);
  assert.equal(inspectUpload(Buffer.from([0xff, 0xf1, 0x50, 0x80, 0x00]), 'audio/aac').ok, true);
  const oversized = Buffer.concat([png, Buffer.alloc(1_048_576)]);
  assert.deepEqual(inspectUpload(oversized, 'image/png'), { ok: false, reason: 'too_large' });
  assert.equal(inspectUpload(png, 'image/jpeg').ok, false);
  for (const [bytes, declared] of [
    [Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>'), 'image/svg+xml'],
    [Buffer.from('<!DOCTYPE html><html></html>'), 'text/html'],
    [Buffer.from('console.log("no")'), 'application/javascript'],
    [Buffer.from('javascript:alert(1)'), 'text/javascript'],
  ] as const) {
    const result = inspectUpload(bytes, declared);
    assert.equal(result.ok, false);
    if (!result.ok) assert.equal(result.reason, 'blocked');
  }
});

test('a parent token and a missing role are rejected on staff routes', async () => {
  const parent = await app.inject({
    method: 'GET',
    url: '/admin/v1/drafts',
    headers: {
      authorization: testAuthorization({
        sub: 'admin-test-parent',
        aud: 'parent',
        roles: ['publisher'],
      }),
    },
  });
  assert.equal(parent.statusCode, 401);
  assert.equal(parent.json().error.code, 'UNAUTHENTICATED');

  const missingMfa = await app.inject({
    method: 'POST',
    url: '/admin/v1/drafts/00000000-0000-4000-8000-000000000001/publish',
    headers: {
      authorization: testAuthorization({
        sub: 'admin-test-publisher',
        mfa: false,
        roles: ['publisher'],
      }),
    },
  });
  assert.equal(missingMfa.statusCode, 401);
  assert.equal(missingMfa.json().error.message, 'MFA is required.');

  const emptyRole = await app.inject({
    method: 'GET',
    url: '/admin/v1/drafts',
    headers: {
      authorization: testAuthorization({ sub: 'admin-test-empty', roles: [] }),
    },
  });
  assert.equal(emptyRole.statusCode, 403);
  assert.equal(emptyRole.json().error.code, 'FORBIDDEN');

  const authorPublish = await app.inject({
    method: 'POST',
    url: '/admin/v1/drafts/00000000-0000-4000-8000-000000000001/publish',
    headers: auth('admin-test-author', ['author']),
  });
  assert.equal(authorPublish.statusCode, 403);
  assert.equal(authorPublish.json().error.code, 'FORBIDDEN');

  const profiles = await app.inject({
    method: 'POST',
    url: '/api/v1/profiles',
    headers: { ...auth('admin-test-author', ['publisher']), 'content-type': 'application/json' },
    payload: {},
  });
  assert.equal(profiles.statusCode, 404);
});

test('the test identity provider is not the default', async () => {
  const closed = await buildApp({ prisma, config, logger: false });
  const response = await closed.inject({
    method: 'GET',
    url: '/admin/v1/audit',
    headers: auth('admin-test-publisher', ['publisher']),
  });
  assert.equal(response.statusCode, 401);
  assert.equal(response.json().error.code, 'UNAUTHENTICATED');
  await closed.close();
});

test('a reviewed draft publishes a new lesson and a bad upload is rejected', async () => {
  try {
    const svg = await app.inject({
      method: 'POST',
      url: '/admin/v1/assets',
      headers: {
        ...auth('admin-test-author', ['author']),
        'content-type': 'image/svg+xml',
        'x-asset-id': 'img.stars.svg',
      },
      payload: Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
    });
    assert.equal(svg.statusCode, 400);
    assert.equal(svg.json().error.code, 'VALIDATION_ERROR');
    const html = await app.inject({
      method: 'POST',
      url: '/admin/v1/assets',
      headers: {
        ...auth('admin-test-author', ['author']),
        'content-type': 'text/html',
        'x-asset-id': 'img.stars.html',
      },
      payload: Buffer.from('<!DOCTYPE html><html></html>'),
    });
    assert.equal(html.statusCode, 400);
    const javascript = await app.inject({
      method: 'POST',
      url: '/admin/v1/assets',
      headers: {
        ...auth('admin-test-author', ['author']),
        'content-type': 'application/javascript',
        'x-asset-id': 'img.stars.js',
      },
      payload: Buffer.from('console.log("no")'),
    });
    assert.equal(javascript.statusCode, 400);
    assert.equal(await prisma.mediaAsset.findUnique({ where: { assetId: 'img.stars.js' } }), null);

    const uploaded = await app.inject({
      method: 'POST',
      url: '/admin/v1/assets',
      headers: {
        ...auth('admin-test-author', ['author']),
        'content-type': 'image/png',
        'x-asset-id': assetId,
      },
      payload: png,
    });
    assert.equal(uploaded.statusCode, 201);
    assert.equal(uploaded.json().sha256, pngSha256);
    const hidden = await app.inject({ method: 'GET', url: `/api/v1/assets/${assetId}` });
    assert.equal(hidden.statusCode, 404);

    const created = await app.inject({
      method: 'POST',
      url: '/admin/v1/drafts',
      headers: auth('admin-test-author', ['author']),
      payload: starsLesson('Two stars'),
    });
    assert.equal(created.statusCode, 201);
    const draft = created.json() as { draftId: string; locales: Record<string, string> };
    assert.deepEqual(draft.locales, { en: 'pending', hi: 'pending', ta: 'pending' });

    const selfReview = await app.inject({
      method: 'POST',
      url: `/admin/v1/drafts/${draft.draftId}/reviews/education`,
      headers: auth('admin-test-author', ['author', 'reviewer_education']),
      payload: { decision: 'approved' },
    });
    assert.equal(selfReview.statusCode, 403);
    assert.match(selfReview.json().error.message, /own lesson/);

    assert.equal(
      (
        await app.inject({
          method: 'POST',
          url: `/admin/v1/drafts/${draft.draftId}/reviews/education`,
          headers: auth('admin-test-education', ['reviewer_education']),
          payload: { decision: 'approved' },
        })
      ).statusCode,
      200,
    );
    const edited = await app.inject({
      method: 'PATCH',
      url: `/admin/v1/drafts/${draft.draftId}`,
      headers: auth('admin-test-author', ['author']),
      payload: starsLesson('Two bright stars'),
    });
    assert.equal(edited.statusCode, 200);
    assert.equal(edited.json().educationStatus, 'pending');
    const tooSoon = await app.inject({
      method: 'POST',
      url: `/admin/v1/drafts/${draft.draftId}/publish`,
      headers: auth('admin-test-publisher', ['publisher']),
    });
    assert.equal(tooSoon.statusCode, 400);
    assert.equal(tooSoon.json().error.message, 'Reviews are not complete.');

    assert.equal(
      (
        await app.inject({
          method: 'POST',
          url: `/admin/v1/drafts/${draft.draftId}/reviews/education`,
          headers: auth('admin-test-education', ['reviewer_education']),
          payload: { decision: 'approved' },
        })
      ).statusCode,
      200,
    );
    for (const locale of ['en', 'hi', 'ta']) {
      const reviewed = await app.inject({
        method: 'POST',
        url: `/admin/v1/drafts/${draft.draftId}/reviews/language`,
        headers: auth('admin-test-language', ['reviewer_language']),
        payload: { locale, decision: 'approved' },
      });
      assert.equal(reviewed.statusCode, 200, locale);
    }
    assert.equal(
      (
        await app.inject({
          method: 'POST',
          url: `/admin/v1/drafts/${draft.draftId}/reviews/rights`,
          headers: auth('admin-test-rights', ['reviewer_rights']),
          payload: { decision: 'approved' },
        })
      ).statusCode,
      200,
    );

    const authorPublish = await app.inject({
      method: 'POST',
      url: `/admin/v1/drafts/${draft.draftId}/publish`,
      headers: auth('admin-test-author', ['author']),
    });
    assert.equal(authorPublish.statusCode, 403);

    const published = await app.inject({
      method: 'POST',
      url: `/admin/v1/drafts/${draft.draftId}/publish`,
      headers: auth('admin-test-publisher', ['publisher']),
    });
    assert.equal(published.statusCode, 200);
    assert.equal(published.json().contentId, contentId);
    assert.equal(published.json().contentVersion, 1);

    const lesson = await app.inject({
      method: 'GET',
      url: `/api/v1/content/${contentId}/versions/1`,
    });
    assert.equal(lesson.statusCode, 200);
    assert.match(lesson.body, /Two bright stars/);
    const manifest = await app.inject({
      method: 'GET',
      url: '/api/v1/content/manifest?locale=en&ageBand=4-5',
    });
    const ids = (manifest.json() as { items: Array<{ contentId: string }> }).items.map(
      (item) => item.contentId,
    );
    assert.ok(ids.includes(contentId));
    const bytes = await app.inject({ method: 'GET', url: `/api/v1/assets/${assetId}` });
    assert.equal(bytes.statusCode, 200);

    const authorAudit = await app.inject({
      method: 'GET',
      url: '/admin/v1/audit',
      headers: auth('admin-test-author', ['author']),
    });
    assert.equal(authorAudit.statusCode, 403);
    const audit = await app.inject({
      method: 'GET',
      url: '/admin/v1/audit',
      headers: auth('admin-test-publisher', ['publisher']),
    });
    assert.equal(audit.statusCode, 200);
    const actions = (
      audit.json() as { events: Array<{ action: string; contentId: string }> }
    ).events
      .filter((event) => event.contentId === contentId)
      .map((event) => event.action);
    assert.ok(actions.includes('published'));
    assert.ok(actions.includes('education_reviewed'));
    assert.ok(actions.includes('language_reviewed'));
    assert.ok(actions.includes('rights_reviewed'));

    const unpublished = await app.inject({
      method: 'POST',
      url: `/admin/v1/content/${contentId}/unpublish`,
      headers: auth('admin-test-publisher', ['publisher']),
    });
    assert.equal(unpublished.statusCode, 200);
    assert.equal(unpublished.json().status, 'unpublished');
    const gone = await app.inject({
      method: 'GET',
      url: `/api/v1/content/${contentId}/versions/1`,
    });
    assert.equal(gone.statusCode, 404);
    assert.equal(gone.json().error.code, 'CONTENT_VERSION_UNAVAILABLE');
    const restored = await app.inject({
      method: 'GET',
      url: '/api/v1/content/manifest?locale=en&ageBand=4-5',
    });
    assert.deepEqual(
      (restored.json() as { items: Array<{ contentId: string }> }).items.map(
        (item) => item.contentId,
      ),
      ['animal.elephant.001', 'count.birds.001', 'order.morning.001'],
    );
    const elephant = await app.inject({
      method: 'GET',
      url: '/api/v1/content/animal.elephant.001/versions/1',
    });
    assert.equal(elephant.statusCode, 200);
  } finally {
    await cleanup();
  }
});

function starsLesson(title: string) {
  return {
    schemaVersion: '1.0',
    contentId,
    categoryId: 'numbers',
    ageRange: { minMonths: 49, maxMonths: 60 },
    learningObjectives: ['count_to_two'],
    difficulty: 1,
    estimatedDurationSeconds: 30,
    localizations: {
      en: {
        title,
        instruction: 'Count two stars.',
        feedbackCorrect: 'That is two.',
        feedbackRetry: 'Not two yet. Try again.',
      },
      hi: {
        title: 'दो तारे',
        instruction: 'दो तारे गिनें।',
        feedbackCorrect: 'यह दो हैं।',
        feedbackRetry: 'अभी दो नहीं। फिर कोशिश करें।',
      },
      ta: {
        title: 'இரண்டு நட்சத்திரங்கள்',
        instruction: 'இரண்டு நட்சத்திரங்களை எண்ணுங்கள்.',
        feedbackCorrect: 'இது இரண்டு.',
        feedbackRetry: 'இன்னும் இரண்டு இல்லை. மீண்டும் முயலுங்கள்.',
      },
    },
    assets: [{ assetId, mediaType: 'image', sha256: pngSha256 }],
    interaction: {
      type: 'counting',
      completionRule: 'count_matches',
      retryPolicy: 'unlimited',
      targetCount: 2,
      maxCount: 5,
    },
    accessibility: {
      imageLabel: { en: 'Stars', hi: 'तारे', ta: 'நட்சத்திரங்கள்' },
      requiresAudio: false,
    },
  };
}

function auth(
  sub: string,
  roles: Array<
    'author' | 'reviewer_education' | 'reviewer_language' | 'reviewer_rights' | 'publisher'
  >,
) {
  return { authorization: testAuthorization({ sub, roles }) };
}

async function cleanup(): Promise<void> {
  await prisma.contentAssetRef.deleteMany({ where: { contentId } });
  await prisma.contentLocalization.deleteMany({ where: { contentId } });
  await prisma.contentVersion.deleteMany({ where: { contentId } });
  const drafts = await prisma.contentDraft.findMany({
    where: { contentId },
    select: { id: true },
  });
  if (drafts.length > 0) {
    await prisma.draftLocaleReview.deleteMany({
      where: { draftId: { in: drafts.map((draft) => draft.id) } },
    });
  }
  await prisma.contentDraft.deleteMany({ where: { contentId } });
  await prisma.contentAuditEvent.deleteMany({
    where: { actorSub: { startsWith: 'admin-test-' } },
  });
  const uploaded = [assetId, 'img.stars.svg', 'img.stars.html', 'img.stars.js'];
  await prisma.mediaAssetBlob.deleteMany({ where: { assetId: { in: uploaded } } });
  await prisma.mediaAsset.deleteMany({ where: { assetId: { in: uploaded } } });
}
