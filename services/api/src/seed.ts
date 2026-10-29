import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PrismaClient, type Prisma } from '@prisma/client';
import { Ajv2020 } from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';
import { canonicalJson, sha256Hex } from './canonical.js';
import { loadConfig } from './config.js';
import { lessonDocumentSchema } from './schemas/lesson.js';

const packId = 'pack.animal.elephant.001';

export function defaultFixtureDir(): string {
  return path.resolve(process.cwd(), '../../infrastructure/fixtures');
}

export function defaultSchemaPath(): string {
  return path.resolve(process.cwd(), '../../packages/content_schema/lesson-document.schema.json');
}

export async function seedDatabase(
  prisma: PrismaClient,
  fixtureDir: string,
  schemaPath: string,
): Promise<void> {
  const lessonPath = path.join(fixtureDir, 'animal.elephant.001.json');
  const checksumPath = path.join(fixtureDir, 'checksums.json');
  const raw = JSON.parse(readFileSync(lessonPath, 'utf8')) as unknown;
  const checksums = JSON.parse(readFileSync(checksumPath, 'utf8')) as {
    payloadSha256: string;
    assets: Record<string, { file: string; sha256: string; bytes: number }>;
  };
  assertSchema(raw, schemaPath);
  const parsed = lessonDocumentSchema.parse(raw);
  const canonical = canonicalJson(parsed);
  const payloadSha256 = sha256Hex(canonical);
  if (payloadSha256 !== checksums.payloadSha256) {
    throw new Error('lesson payload sha256 does not match checksums.json');
  }

  const assetRows = parsed.assets.map((asset) => {
    const recorded = checksums.assets[asset.assetId];
    if (!recorded || recorded.sha256 !== asset.sha256) {
      throw new Error(`missing checksum for ${asset.assetId}`);
    }
    const bytes = readFileSync(path.join(fixtureDir, recorded.file));
    const actual = sha256Hex(bytes);
    if (actual !== asset.sha256 || bytes.length !== recorded.bytes) {
      throw new Error(`asset bytes do not match ${asset.assetId}`);
    }
    return { asset, recorded, byteSize: bytes.length };
  });

  const existing = await prisma.contentVersion.findUnique({
    where: { contentId_contentVersion: { contentId: parsed.contentId, contentVersion: 1 } },
  });
  if (existing) {
    if (existing.payloadSha256 !== payloadSha256 || existing.status !== 'published') {
      throw new Error('published lesson already exists with a different payload');
    }
    return;
  }

  const packMaterial = `${parsed.contentId}:${parsed.contentVersion}\n`;
  const totalBytes =
    assetRows.reduce((sum, row) => sum + row.byteSize, 0) + Buffer.byteLength(canonical);

  await prisma.$transaction(async (tx) => {
    await tx.contentVersion.create({
      data: {
        contentId: parsed.contentId,
        contentVersion: parsed.contentVersion,
        schemaVersion: parsed.schemaVersion,
        categoryId: parsed.categoryId,
        ageMinMonths: parsed.ageRange.minMonths,
        ageMaxMonths: parsed.ageRange.maxMonths,
        interactionType: parsed.interaction.type,
        status: 'published',
        payload: parsed as unknown as Prisma.InputJsonValue,
        payloadSha256,
      },
    });

    for (const [locale, copy] of Object.entries(parsed.localizations)) {
      if (!copy) continue;
      await tx.contentLocalization.create({
        data: {
          contentId: parsed.contentId,
          contentVersion: parsed.contentVersion,
          locale,
          title: copy.title,
          instruction: copy.instruction,
          feedbackCorrect: copy.feedbackCorrect,
          reviewStatus: 'engineering_fixture',
        },
      });
    }

    for (const row of assetRows) {
      await tx.mediaAsset.upsert({
        where: { assetId: row.asset.assetId },
        update: {},
        create: {
          assetId: row.asset.assetId,
          mediaType: row.asset.mediaType,
          locale: localeForAsset(row.asset.assetId),
          objectKey: row.recorded.file,
          sha256: row.asset.sha256,
          byteSize: row.byteSize,
          rightsStatus: 'original_fixture',
        },
      });
      await tx.contentAssetRef.create({
        data: {
          contentId: parsed.contentId,
          contentVersion: parsed.contentVersion,
          assetId: row.asset.assetId,
        },
      });
    }

    await tx.contentPack.create({
      data: {
        packId,
        packVersion: 1,
        totalBytes,
        checksumSha256: sha256Hex(packMaterial),
        minAppVersion: '0.1.0',
        status: 'published',
      },
    });
    await tx.contentPackItem.create({
      data: {
        packId,
        packVersion: 1,
        contentId: parsed.contentId,
        contentVersion: parsed.contentVersion,
        position: 0,
      },
    });
  });
}

function localeForAsset(assetId: string): string | null {
  if (assetId.includes('.en.')) return 'en';
  if (assetId.includes('.hi.')) return 'hi';
  if (assetId.includes('.ta.')) return 'ta';
  return null;
}

function assertSchema(value: unknown, schemaPath: string): void {
  const schema = JSON.parse(readFileSync(schemaPath, 'utf8')) as Record<string, unknown>;
  const ajv = new Ajv2020({ allErrors: true, strict: false });
  const applyFormats = addFormats as unknown as (instance: Ajv2020) => void;
  applyFormats(ajv);
  const validate = ajv.compile(schema);
  if (!validate(value)) {
    throw new Error(`lesson document failed JSON schema: ${ajv.errorsText(validate.errors)}`);
  }
}

const invokedDirectly = process.argv[1]
  ? path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
  : false;

if (invokedDirectly) {
  const config = loadConfig();
  const prisma = new PrismaClient();
  try {
    await seedDatabase(
      prisma,
      config.fixtureDir || defaultFixtureDir(),
      config.schemaPath || defaultSchemaPath(),
    );
  } finally {
    await prisma.$disconnect();
  }
}
