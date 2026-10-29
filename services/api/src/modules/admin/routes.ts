import { randomUUID } from 'node:crypto';
import type { Prisma, PrismaClient } from '@prisma/client';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { canonicalJson, sha256Hex } from '../../canonical.js';
import type { AppConfig } from '../../config.js';
import { sendError, type ErrorCode } from '../../errors.js';
import {
  contentIdSchema,
  lessonDocumentSchema,
  type LessonDocument,
} from '../../schemas/lesson.js';
import {
  staffClaims,
  type AccessClaims,
  type IdentityProvider,
  type StaffRole,
} from './identity.js';
import { declaredMediaType, inspectUpload } from './uploads.js';

const uploadContentTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'audio/mpeg',
  'audio/mp4',
  'audio/aac',
  'image/svg+xml',
  'text/html',
  'application/xhtml+xml',
  'text/javascript',
  'application/javascript',
  'text/ecmascript',
  'application/ecmascript',
  'application/octet-stream',
];

const draftIdSchema = z.string().uuid();
const decisionSchema = z.object({ decision: z.enum(['approved', 'rejected']) }).strict();
const languageReviewSchema = z
  .object({
    locale: z.enum(['en', 'hi', 'ta']),
    decision: z.enum(['approved', 'rejected']),
  })
  .strict();

const locales = ['en', 'hi', 'ta'] as const;

export function registerAdminRoutes(
  app: FastifyInstance,
  prisma: PrismaClient,
  config: AppConfig,
  identity: IdentityProvider,
): void {
  for (const type of uploadContentTypes) {
    app.addContentTypeParser(type, { parseAs: 'buffer' }, (_request, body, done) => {
      done(null, body);
    });
  }

  app.addHook('onRequest', async (request, reply) => {
    const claims = identity.verify(request.headers.authorization);
    if (!claims || claims.aud !== 'staff') {
      await sendError(reply, 401, 'UNAUTHENTICATED', 'Staff sign-in is required.', false);
      return;
    }
    if (!claims.amr.includes('mfa')) {
      await sendError(reply, 401, 'UNAUTHENTICATED', 'MFA is required.', false);
      return;
    }
    if (claims.roles.length === 0) {
      await sendError(reply, 403, 'FORBIDDEN', 'That role is required.', false);
      return;
    }
    request.staffClaims = claims;
  });

  const limit = { config: { rateLimit: { max: config.rateAdmin, timeWindow: '1 minute' } } };

  app.get('/drafts', limit, async (request, reply) => {
    const rows = await prisma.contentDraft.findMany({
      orderBy: { updatedAt: 'desc' },
      take: 100,
    });
    return reply.send({
      drafts: rows.map((row) => ({
        draftId: row.id,
        contentId: row.contentId,
        state: row.state,
        authorSub: row.authorSub,
      })),
    });
  });

  app.post('/drafts', limit, async (request, reply) => {
    if (!(await requireRole(request, reply, 'author'))) return;
    const document = parseDraftDocument(request.body);
    if (!document) {
      return sendError(
        reply,
        400,
        'VALIDATION_ERROR',
        'Draft is not a three-locale lesson.',
        false,
      );
    }
    const claims = staffClaims(request);
    const draftId = randomUUID();
    await prisma.$transaction(async (tx) => {
      await tx.contentDraft.create({
        data: {
          id: draftId,
          contentId: document.contentId,
          authorSub: claims.sub,
          payload: document as unknown as Prisma.InputJsonValue,
          updatedAt: new Date(),
          localeReviews: {
            create: locales.map((locale) => ({ locale, status: 'pending' })),
          },
        },
      });
      await writeAudit(tx, {
        actorSub: claims.sub,
        action: 'draft_created',
        contentId: document.contentId,
        draftId,
        detail: {},
      });
    });
    return reply.code(201).send(await draftView(prisma, draftId));
  });

  app.get('/drafts/:draftId', limit, async (request, reply) => {
    const draftId = readDraftId(request);
    if (!draftId) return sendError(reply, 400, 'VALIDATION_ERROR', 'Draft id is not valid.', false);
    const view = await draftView(prisma, draftId);
    if (!view) return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Draft was not found.', false);
    return reply.send(view);
  });

  app.patch('/drafts/:draftId', limit, async (request, reply) => {
    if (!(await requireRole(request, reply, 'author'))) return;
    const draftId = readDraftId(request);
    if (!draftId) return sendError(reply, 400, 'VALIDATION_ERROR', 'Draft id is not valid.', false);
    const document = parseDraftDocument(request.body);
    if (!document) {
      return sendError(
        reply,
        400,
        'VALIDATION_ERROR',
        'Draft is not a three-locale lesson.',
        false,
      );
    }
    const existing = await prisma.contentDraft.findUnique({ where: { id: draftId } });
    if (!existing || existing.state !== 'open') {
      return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Draft was not found.', false);
    }
    const claims = staffClaims(request);
    if (existing.authorSub !== claims.sub) {
      return sendError(reply, 403, 'FORBIDDEN', 'Only the author can edit this draft.', false);
    }
    await prisma.$transaction(async (tx) => {
      await tx.contentDraft.update({
        where: { id: draftId },
        data: {
          contentId: document.contentId,
          payload: document as unknown as Prisma.InputJsonValue,
          educationStatus: 'pending',
          educationReviewerSub: null,
          rightsStatus: 'pending',
          rightsReviewerSub: null,
        },
      });
      await tx.draftLocaleReview.updateMany({
        where: { draftId },
        data: { status: 'pending', reviewerSub: null },
      });
      await writeAudit(tx, {
        actorSub: claims.sub,
        action: 'draft_updated',
        contentId: document.contentId,
        draftId,
        detail: {},
      });
    });
    return reply.send(await draftView(prisma, draftId));
  });

  app.post('/assets', { bodyLimit: 2_097_152, ...limit }, async (request, reply) => {
    if (!(await requireRole(request, reply, 'author'))) return;
    const assetId = contentIdSchema.safeParse(request.headers['x-asset-id']);
    if (!assetId.success) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Asset id is not valid.', false);
    }
    const bytes = Buffer.isBuffer(request.body) ? request.body : Buffer.from([]);
    const inspection = inspectUpload(bytes, declaredMediaType(request.headers['content-type']));
    if (!inspection.ok) {
      if (inspection.reason === 'too_large') {
        return sendError(reply, 413, 'PAYLOAD_TOO_LARGE', 'That file is too large.', false);
      }
      return sendError(reply, 400, 'VALIDATION_ERROR', 'This file type is not allowed.', false);
    }
    const existing = await prisma.mediaAsset.findUnique({ where: { assetId: assetId.data } });
    if (existing) {
      return sendError(reply, 409, 'REVISION_CONFLICT', 'That asset id already exists.', false);
    }
    const claims = staffClaims(request);
    const checksum = sha256Hex(bytes);
    await prisma.$transaction(async (tx) => {
      await tx.mediaAsset.create({
        data: {
          assetId: assetId.data,
          mediaType: inspection.mediaType,
          objectKey: 'upload',
          sha256: checksum,
          byteSize: bytes.length,
          rightsStatus: 'pending',
          blob: { create: { contentType: inspection.contentType, bytes: Uint8Array.from(bytes) } },
        },
      });
      await writeAudit(tx, {
        actorSub: claims.sub,
        action: 'asset_uploaded',
        contentId: null,
        draftId: null,
        detail: { assetId: assetId.data, sha256: checksum },
      });
    });
    return reply.code(201).send({
      assetId: assetId.data,
      mediaType: inspection.mediaType,
      contentType: inspection.contentType,
      sha256: checksum,
      byteSize: bytes.length,
    });
  });

  app.post('/drafts/:draftId/reviews/education', limit, async (request, reply) => {
    return reviewLesson(prisma, request, reply, 'education');
  });

  app.post('/drafts/:draftId/reviews/rights', limit, async (request, reply) => {
    return reviewLesson(prisma, request, reply, 'rights');
  });

  app.post('/drafts/:draftId/reviews/language', limit, async (request, reply) => {
    const draftId = readDraftId(request);
    if (!draftId) return sendError(reply, 400, 'VALIDATION_ERROR', 'Draft id is not valid.', false);
    const body = languageReviewSchema.safeParse(request.body);
    if (!body.success) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Review is not valid.', false);
    }
    const draft = await prisma.contentDraft.findUnique({ where: { id: draftId } });
    if (!draft || draft.state !== 'open') {
      return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Draft was not found.', false);
    }
    const claims = staffClaims(request);
    if (draft.authorSub === claims.sub) {
      return sendError(
        reply,
        403,
        'FORBIDDEN',
        'An author cannot approve their own lesson.',
        false,
      );
    }
    if (!claims.roles.includes('reviewer_language')) {
      return sendError(reply, 403, 'FORBIDDEN', 'That role is required.', false);
    }
    await prisma.$transaction(async (tx) => {
      await tx.draftLocaleReview.update({
        where: { draftId_locale: { draftId, locale: body.data.locale } },
        data: { status: body.data.decision, reviewerSub: claims.sub },
      });
      await writeAudit(tx, {
        actorSub: claims.sub,
        action: 'language_reviewed',
        contentId: draft.contentId,
        draftId,
        detail: { locale: body.data.locale, decision: body.data.decision },
      });
    });
    return reply.send(await draftView(prisma, draftId));
  });

  app.post('/drafts/:draftId/publish', limit, async (request, reply) => {
    if (!(await requireRole(request, reply, 'publisher'))) return;
    const draftId = readDraftId(request);
    if (!draftId) return sendError(reply, 400, 'VALIDATION_ERROR', 'Draft id is not valid.', false);
    const claims = staffClaims(request);
    const result = await prisma.$transaction(async (tx) => {
      const draft = await tx.contentDraft.findUnique({
        where: { id: draftId },
        include: { localeReviews: true },
      });
      if (!draft || draft.state !== 'open') return { missing: true as const };
      const ready = reviewsReady(draft);
      if (!ready) return { invalid: true as const };
      const latest = await tx.contentVersion.findFirst({
        where: { contentId: draft.contentId },
        orderBy: { contentVersion: 'desc' },
      });
      const contentVersion = (latest?.contentVersion ?? 0) + 1;
      const parsed = lessonDocumentSchema.safeParse({
        ...(draft.payload as Record<string, unknown>),
        contentVersion,
      });
      if (!parsed.success || !hasThreeLocales(parsed.data)) return { invalid: true as const };
      for (const asset of parsed.data.assets) {
        const row = await tx.mediaAsset.findUnique({ where: { assetId: asset.assetId } });
        if (!row || row.sha256 !== asset.sha256 || row.mediaType !== asset.mediaType) {
          return { invalid: true as const };
        }
      }
      const canonical = canonicalJson(parsed.data);
      const payloadSha256 = sha256Hex(canonical);
      await tx.contentVersion.create({
        data: {
          contentId: parsed.data.contentId,
          contentVersion,
          schemaVersion: parsed.data.schemaVersion,
          categoryId: parsed.data.categoryId,
          ageMinMonths: parsed.data.ageRange.minMonths,
          ageMaxMonths: parsed.data.ageRange.maxMonths,
          interactionType: parsed.data.interaction.type,
          status: 'published',
          payload: parsed.data as unknown as Prisma.InputJsonValue,
          payloadSha256,
        },
      });
      for (const locale of locales) {
        const copy = parsed.data.localizations[locale];
        if (!copy) continue;
        await tx.contentLocalization.create({
          data: {
            contentId: parsed.data.contentId,
            contentVersion,
            locale,
            title: copy.title,
            instruction: copy.instruction,
            feedbackCorrect: copy.feedbackCorrect,
            reviewStatus: 'approved',
          },
        });
      }
      for (const asset of parsed.data.assets) {
        await tx.mediaAsset.update({
          where: { assetId: asset.assetId },
          data: { rightsStatus: 'approved' },
        });
        await tx.contentAssetRef.create({
          data: {
            contentId: parsed.data.contentId,
            contentVersion,
            assetId: asset.assetId,
          },
        });
      }
      await tx.contentDraft.update({
        where: { id: draftId },
        data: { state: 'published', publishedVersion: contentVersion },
      });
      await writeAudit(tx, {
        actorSub: claims.sub,
        action: 'published',
        contentId: parsed.data.contentId,
        draftId,
        detail: { contentVersion, payloadSha256 },
      });
      return {
        published: {
          contentId: parsed.data.contentId,
          contentVersion,
          payloadSha256,
          status: 'published' as const,
        },
      };
    });
    if ('missing' in result) {
      return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Draft was not found.', false);
    }
    if ('invalid' in result) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Reviews are not complete.', false);
    }
    return reply.send(result.published);
  });

  app.post('/content/:contentId/unpublish', limit, async (request, reply) => {
    if (!(await requireRole(request, reply, 'publisher'))) return;
    const params = request.params as { contentId?: string };
    const contentId = contentIdSchema.safeParse(params.contentId);
    if (!contentId.success) {
      return sendError(reply, 400, 'VALIDATION_ERROR', 'Content id is not valid.', false);
    }
    const claims = staffClaims(request);
    const row = await prisma.contentVersion.findFirst({
      where: { contentId: contentId.data, status: 'published' },
      orderBy: { contentVersion: 'desc' },
    });
    if (!row) {
      return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Content was not found.', false);
    }
    await prisma.$transaction(async (tx) => {
      await tx.contentVersion.update({
        where: {
          contentId_contentVersion: {
            contentId: row.contentId,
            contentVersion: row.contentVersion,
          },
        },
        data: { status: 'unpublished' },
      });
      await writeAudit(tx, {
        actorSub: claims.sub,
        action: 'unpublished',
        contentId: row.contentId,
        draftId: null,
        detail: { contentVersion: row.contentVersion },
      });
    });
    return reply.send({
      contentId: row.contentId,
      contentVersion: row.contentVersion,
      status: 'unpublished',
    });
  });

  app.get('/audit', limit, async (request, reply) => {
    if (!(await requireRole(request, reply, 'publisher', 'administrator'))) return;
    const events = await prisma.contentAuditEvent.findMany({
      orderBy: { at: 'desc' },
      take: 100,
    });
    return reply.send({
      events: events.map((event) => ({
        id: event.id,
        at: event.at.toISOString(),
        actorSub: event.actorSub,
        action: event.action,
        contentId: event.contentId,
        draftId: event.draftId,
        detail: event.detail,
      })),
    });
  });
}

async function reviewLesson(
  prisma: PrismaClient,
  request: FastifyRequest,
  reply: FastifyReply,
  kind: 'education' | 'rights',
) {
  const draftId = readDraftId(request);
  if (!draftId) return sendError(reply, 400, 'VALIDATION_ERROR', 'Draft id is not valid.', false);
  const body = decisionSchema.safeParse(request.body);
  if (!body.success) {
    return sendError(reply, 400, 'VALIDATION_ERROR', 'Review is not valid.', false);
  }
  const draft = await prisma.contentDraft.findUnique({ where: { id: draftId } });
  if (!draft || draft.state !== 'open') {
    return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Draft was not found.', false);
  }
  const claims = staffClaims(request);
  if (draft.authorSub === claims.sub) {
    return sendError(reply, 403, 'FORBIDDEN', 'An author cannot approve their own lesson.', false);
  }
  const role: StaffRole = kind === 'education' ? 'reviewer_education' : 'reviewer_rights';
  if (!claims.roles.includes(role)) {
    return sendError(reply, 403, 'FORBIDDEN', 'That role is required.', false);
  }
  await prisma.$transaction(async (tx) => {
    await tx.contentDraft.update({
      where: { id: draftId },
      data:
        kind === 'education'
          ? { educationStatus: body.data.decision, educationReviewerSub: claims.sub }
          : { rightsStatus: body.data.decision, rightsReviewerSub: claims.sub },
    });
    await writeAudit(tx, {
      actorSub: claims.sub,
      action: kind === 'education' ? 'education_reviewed' : 'rights_reviewed',
      contentId: draft.contentId,
      draftId,
      detail: { decision: body.data.decision },
    });
  });
  return reply.send(await draftView(prisma, draftId));
}

function parseDraftDocument(input: unknown): LessonDocument | null {
  if (!input || typeof input !== 'object' || Array.isArray(input)) return null;
  const parsed = lessonDocumentSchema.safeParse({
    ...(input as Record<string, unknown>),
    contentVersion: 1,
  });
  if (!parsed.success || !hasThreeLocales(parsed.data)) return null;
  return parsed.data;
}

function hasThreeLocales(document: LessonDocument): boolean {
  return Boolean(
    document.localizations.en && document.localizations.hi && document.localizations.ta,
  );
}

function reviewsReady(draft: {
  educationStatus: string;
  educationReviewerSub: string | null;
  rightsStatus: string;
  rightsReviewerSub: string | null;
  authorSub: string;
  localeReviews: Array<{ locale: string; status: string; reviewerSub: string | null }>;
}): boolean {
  if (draft.educationStatus !== 'approved' || draft.rightsStatus !== 'approved') return false;
  if (!draft.educationReviewerSub || draft.educationReviewerSub === draft.authorSub) return false;
  if (!draft.rightsReviewerSub || draft.rightsReviewerSub === draft.authorSub) return false;
  return locales.every((locale) => {
    const review = draft.localeReviews.find((item) => item.locale === locale);
    return (
      review?.status === 'approved' &&
      Boolean(review.reviewerSub) &&
      review.reviewerSub !== draft.authorSub
    );
  });
}

async function draftView(prisma: PrismaClient, draftId: string) {
  const draft = await prisma.contentDraft.findUnique({
    where: { id: draftId },
    include: { localeReviews: true },
  });
  if (!draft) return null;
  const localeStatus = Object.fromEntries(
    locales.map((locale) => [
      locale,
      draft.localeReviews.find((review) => review.locale === locale)?.status ?? 'pending',
    ]),
  );
  return {
    draftId: draft.id,
    contentId: draft.contentId,
    state: draft.state,
    authorSub: draft.authorSub,
    educationStatus: draft.educationStatus,
    rightsStatus: draft.rightsStatus,
    locales: localeStatus,
    payload: draft.payload,
  };
}

function readDraftId(request: FastifyRequest): string | null {
  const params = request.params as { draftId?: string };
  const parsed = draftIdSchema.safeParse(params.draftId);
  return parsed.success ? parsed.data : null;
}

async function requireRole(
  request: FastifyRequest,
  reply: FastifyReply,
  ...roles: StaffRole[]
): Promise<boolean> {
  const claims = staffClaims(request);
  if (!roles.some((role) => claims.roles.includes(role))) {
    await sendError(reply, 403, 'FORBIDDEN', 'That role is required.', false);
    return false;
  }
  return true;
}

async function writeAudit(
  tx: Prisma.TransactionClient,
  event: {
    actorSub: string;
    action: string;
    contentId: string | null;
    draftId: string | null;
    detail: Prisma.InputJsonValue;
  },
): Promise<void> {
  await tx.contentAuditEvent.create({
    data: {
      id: randomUUID(),
      actorSub: event.actorSub,
      action: event.action,
      contentId: event.contentId,
      draftId: event.draftId,
      detail: event.detail,
    },
  });
}
