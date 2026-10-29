import { createReadStream } from 'node:fs';
import path from 'node:path';
import type { PrismaClient } from '@prisma/client';
import type { FastifyInstance } from 'fastify';
import { canonicalJson, sha256Hex } from '../../canonical.js';
import type { AppConfig } from '../../config.js';
import { sendError } from '../../errors.js';
import { contentIdSchema, manifestQuerySchema, versionSchema } from '../../schemas/lesson.js';
import { monthsForBand, type AgeBand } from './age-band.js';
import { catalogPackId, PackChecksumError, readPublishedPack } from './packs.js';
import { signAssetUrl, verifyAssetSignature } from './signing.js';

const idPattern = /^[a-z0-9._-]{1,80}$/;

type PayloadShape = {
  estimatedDurationSeconds?: number;
  schemaVersion?: string;
};

export function registerContentRoutes(
  app: FastifyInstance,
  prisma: PrismaClient,
  config: AppConfig,
): void {
  app.get(
    '/content/manifest',
    {
      config: { rateLimit: { max: config.rateManifest, timeWindow: '1 minute' } },
    },
    async (request, reply) => {
      const parsed = manifestQuerySchema.safeParse(request.query);
      if (!parsed.success) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Query parameters are not valid.', false);
      }
      const cursor = decodeCursor(parsed.data.cursor);
      if (cursor === 'invalid') {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Cursor is not valid.', false);
      }
      const [bandMin, bandMax] = monthsForBand(parsed.data.ageBand as AgeBand);
      const rows = await prisma.contentVersion.findMany({
        where: {
          status: 'published',
          ageMinMonths: { lte: bandMax },
          ageMaxMonths: { gte: bandMin },
          localizations: { some: { locale: parsed.data.locale } },
          ...(cursor ? { contentId: { gt: cursor } } : {}),
        },
        orderBy: { contentId: 'asc' },
        take: 101,
        include: {
          localizations: { where: { locale: parsed.data.locale } },
          packItems: {
            where: { pack: { packId: catalogPackId, status: 'published' } },
            take: 1,
          },
        },
      });
      const page = rows.slice(0, 100);
      const items = page.map((row) => {
        const localization = row.localizations[0];
        const payload = row.payload as PayloadShape;
        const pack = row.packItems[0];
        return {
          contentId: row.contentId,
          contentVersion: row.contentVersion,
          schemaVersion: row.schemaVersion,
          categoryId: row.categoryId,
          interactionType: row.interactionType,
          title: localization?.title ?? '',
          estimatedDurationSeconds: payload.estimatedDurationSeconds ?? 0,
          ...(pack ? { packId: pack.packId, packVersion: pack.packVersion } : {}),
          payloadSha256: row.payloadSha256,
        };
      });
      const nextCursor = rows.length > 100 ? encodeCursor(page[page.length - 1]!.contentId) : null;
      const body = {
        manifestVersion: '1',
        locale: parsed.data.locale,
        ageBand: parsed.data.ageBand,
        items,
        nextCursor,
      };
      return sendCanonical(reply, body, 'public, max-age=60');
    },
  );

  app.get(
    '/content/packs/:packId',
    {
      config: { rateLimit: { max: config.rateManifest, timeWindow: '1 minute' } },
    },
    async (request, reply) => {
      const params = request.params as { packId?: string };
      const packId = contentIdSchema.safeParse(params.packId);
      if (!packId.success) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Pack id is not valid.', false);
      }
      try {
        const pack = await readPublishedPack(prisma, packId.data);
        if (!pack) {
          return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Pack was not found.', false);
        }
        return sendCanonical(reply, pack, 'public, max-age=60');
      } catch (error) {
        if (error instanceof PackChecksumError) {
          request.log.error({ packId: packId.data }, 'pack checksum mismatch');
          return sendError(reply, 500, 'INTERNAL', 'Something went wrong.', true);
        }
        throw error;
      }
    },
  );

  app.get(
    '/content/:contentId',
    {
      config: { rateLimit: { max: config.rateLesson, timeWindow: '1 minute' } },
    },
    async (request, reply) => {
      const params = request.params as { contentId?: string };
      const contentId = contentIdSchema.safeParse(params.contentId);
      if (!contentId.success) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Content id is not valid.', false);
      }
      const row = await prisma.contentVersion.findFirst({
        where: { contentId: contentId.data, status: 'published' },
        orderBy: { contentVersion: 'desc' },
      });
      if (!row) {
        return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Content was not found.', false);
      }
      return sendCanonical(reply, {
        contentId: row.contentId,
        contentVersion: row.contentVersion,
        schemaVersion: row.schemaVersion,
        payloadSha256: row.payloadSha256,
        minAppVersion: '0.1.0',
      });
    },
  );

  app.get(
    '/content/:contentId/versions/:version',
    {
      config: { rateLimit: { max: config.rateLesson, timeWindow: '1 minute' } },
    },
    async (request, reply) => {
      const params = request.params as { contentId?: string; version?: string };
      const contentId = contentIdSchema.safeParse(params.contentId);
      if (
        !contentId.success ||
        params.version === undefined ||
        !/^[1-9]\d*$/.test(params.version)
      ) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Content version is not valid.', false);
      }
      const version = versionSchema.parse(params.version);
      const anyRow = await prisma.contentVersion.findFirst({
        where: { contentId: contentId.data },
        select: { contentId: true },
      });
      if (!anyRow) {
        return sendError(reply, 404, 'CONTENT_NOT_FOUND', 'Content was not found.', false);
      }
      const row = await prisma.contentVersion.findUnique({
        where: {
          contentId_contentVersion: { contentId: contentId.data, contentVersion: version },
        },
      });
      if (!row || row.status !== 'published') {
        return sendError(
          reply,
          404,
          'CONTENT_VERSION_UNAVAILABLE',
          'That version is not published.',
          true,
        );
      }
      const canonical = canonicalJson(row.payload);
      if (sha256Hex(canonical) !== row.payloadSha256) {
        request.log.error({ contentId: row.contentId }, 'stored payload hash mismatch');
        return sendError(reply, 500, 'INTERNAL', 'Something went wrong.', true);
      }
      return reply
        .header('ETag', `"${row.payloadSha256}"`)
        .header('Cache-Control', 'public, max-age=31536000, immutable')
        .type('application/json; charset=utf-8')
        .send(canonical);
    },
  );

  app.get(
    '/assets/:assetId',
    {
      config: { rateLimit: { max: config.rateAsset, timeWindow: '1 minute' } },
    },
    async (request, reply) => {
      const params = request.params as { assetId?: string };
      if (!params.assetId || !idPattern.test(params.assetId)) {
        return sendError(reply, 400, 'VALIDATION_ERROR', 'Asset id is not valid.', false);
      }
      const asset = await prisma.mediaAsset.findUnique({ where: { assetId: params.assetId } });
      if (!asset) {
        return sendError(reply, 404, 'ASSET_NOT_FOUND', 'Asset was not found.', false);
      }
      const expiresAt = Math.floor(Date.now() / 1000) + config.assetUrlTtlSeconds;
      return sendCanonical(reply, {
        assetId: asset.assetId,
        mediaType: asset.mediaType,
        sha256: asset.sha256,
        byteSize: asset.byteSize,
        url: signAssetUrl(config.publicBaseUrl, asset.assetId, expiresAt, config.assetSigningKey),
        urlExpiresAt: new Date(expiresAt * 1000).toISOString(),
      });
    },
  );

  app.get(
    '/assets/:assetId/bytes',
    {
      config: { rateLimit: { max: config.rateAsset, timeWindow: '1 minute' } },
    },
    async (request, reply) => {
      const params = request.params as { assetId?: string };
      const query = request.query as { exp?: string; sig?: string };
      if (!params.assetId || !idPattern.test(params.assetId) || !query.exp || !query.sig) {
        return sendError(reply, 404, 'ASSET_NOT_FOUND', 'Asset was not found.', false);
      }
      const ok = verifyAssetSignature(
        params.assetId,
        query.exp,
        query.sig,
        config.assetSigningKey,
        Math.floor(Date.now() / 1000),
      );
      if (!ok) {
        return sendError(reply, 404, 'ASSET_NOT_FOUND', 'Asset was not found.', false);
      }
      const asset = await prisma.mediaAsset.findUnique({ where: { assetId: params.assetId } });
      if (!asset) {
        return sendError(reply, 404, 'ASSET_NOT_FOUND', 'Asset was not found.', false);
      }
      const filePath = path.join(config.fixtureDir, asset.objectKey);
      const type =
        asset.mediaType === 'image'
          ? 'image/png'
          : asset.mediaType === 'audio'
            ? 'audio/mpeg'
            : 'application/octet-stream';
      return reply
        .header('Cache-Control', 'private, max-age=0')
        .type(type)
        .send(createReadStream(filePath));
    },
  );
}

function sendCanonical(
  reply: Parameters<typeof sendError>[0],
  value: unknown,
  cacheControl?: string,
) {
  const body = canonicalJson(value);
  const etag = sha256Hex(body);
  if (cacheControl) reply.header('Cache-Control', cacheControl);
  return reply.header('ETag', `"${etag}"`).type('application/json; charset=utf-8').send(body);
}

function encodeCursor(contentId: string): string {
  return Buffer.from(contentId, 'utf8').toString('base64url');
}

function decodeCursor(cursor: string | undefined): string | null | 'invalid' {
  if (cursor === undefined) return null;
  try {
    const decoded = Buffer.from(cursor, 'base64url').toString('utf8');
    if (!idPattern.test(decoded)) return 'invalid';
    return decoded;
  } catch {
    return 'invalid';
  }
}
