import type { PrismaClient } from '@prisma/client';
import { canonicalJson, sha256Hex } from '../../canonical.js';

export const catalogPackId = 'pack.catalog.001';

export class PackChecksumError extends Error {
  constructor() {
    super('pack checksum does not match its items');
  }
}

type PackPin = { contentId: string; contentVersion: number };

export type PublishedPack = {
  packId: string;
  packVersion: number;
  checksumSha256: string;
  totalBytes: number;
  minAppVersion: string;
  items: Array<PackPin & { position: number; payloadSha256: string }>;
};

/// Checksum of the ordered pins. Position order is the order of [items].
export function packChecksum(items: PackPin[]): string {
  return sha256Hex(items.map((item) => `${item.contentId}:${item.contentVersion}\n`).join(''));
}

export async function ensureCatalogPack(prisma: PrismaClient): Promise<void> {
  const lessons = await prisma.contentVersion.findMany({
    where: { status: 'published' },
    orderBy: { contentId: 'asc' },
    include: { assetRefs: { include: { asset: true } } },
  });
  const pins = lessons.map((lesson) => ({
    contentId: lesson.contentId,
    contentVersion: lesson.contentVersion,
  }));
  const checksum = packChecksum(pins);
  const totalBytes = lessons.reduce((sum, lesson) => {
    const payloadBytes = Buffer.byteLength(canonicalJson(lesson.payload));
    const assetBytes = lesson.assetRefs.reduce((inner, ref) => inner + ref.asset.byteSize, 0);
    return sum + payloadBytes + assetBytes;
  }, 0);
  const published = await prisma.contentPack.findFirst({
    where: { packId: catalogPackId, status: 'published' },
    orderBy: { packVersion: 'desc' },
    include: { items: { orderBy: { position: 'asc' } } },
  });
  if (published) {
    const same =
      published.checksumSha256 === checksum &&
      published.items.length === pins.length &&
      published.items.every(
        (item, index) =>
          item.contentId === pins[index]?.contentId &&
          item.contentVersion === pins[index]?.contentVersion,
      );
    if (!same) {
      throw new Error('published catalog pack does not match the seeded lessons');
    }
    return;
  }
  await publishNextPackVersion(prisma, catalogPackId, pins, totalBytes);
}

export async function publishNextPackVersion(
  prisma: PrismaClient,
  packId: string,
  items: PackPin[],
  totalBytes: number,
): Promise<number> {
  const checksum = packChecksum(items);
  return prisma.$transaction(async (tx) => {
    const current = await tx.contentPack.findFirst({
      where: { packId, status: 'published' },
      orderBy: { packVersion: 'desc' },
    });
    const latest = await tx.contentPack.findFirst({
      where: { packId },
      orderBy: { packVersion: 'desc' },
    });
    const nextVersion = (latest?.packVersion ?? 0) + 1;
    if (current) {
      await tx.contentPack.update({
        where: { packId_packVersion: { packId, packVersion: current.packVersion } },
        data: { status: 'superseded' },
      });
    }
    await tx.contentPack.create({
      data: {
        packId,
        packVersion: nextVersion,
        totalBytes,
        checksumSha256: checksum,
        minAppVersion: '0.1.0',
        status: 'published',
      },
    });
    for (const [position, item] of items.entries()) {
      await tx.contentPackItem.create({
        data: {
          packId,
          packVersion: nextVersion,
          contentId: item.contentId,
          contentVersion: item.contentVersion,
          position,
        },
      });
    }
    return nextVersion;
  });
}

/// The current published pack becomes rolled_back. The newest superseded pack
/// is published again. Lesson payloads are not rewritten.
export async function rollbackPublishedPack(prisma: PrismaClient, packId: string): Promise<number> {
  return prisma.$transaction(async (tx) => {
    const current = await tx.contentPack.findFirst({
      where: { packId, status: 'published' },
      orderBy: { packVersion: 'desc' },
    });
    if (!current) throw new Error('no published pack');
    const previous = await tx.contentPack.findFirst({
      where: { packId, status: 'superseded' },
      orderBy: { packVersion: 'desc' },
    });
    if (!previous) throw new Error('no previous manifest');
    await tx.contentPack.update({
      where: { packId_packVersion: { packId, packVersion: current.packVersion } },
      data: { status: 'rolled_back' },
    });
    await tx.contentPack.update({
      where: { packId_packVersion: { packId, packVersion: previous.packVersion } },
      data: { status: 'published' },
    });
    return previous.packVersion;
  });
}

export async function readPublishedPack(
  prisma: PrismaClient,
  packId: string,
): Promise<PublishedPack | null> {
  const pack = await prisma.contentPack.findFirst({
    where: { packId, status: 'published' },
    orderBy: { packVersion: 'desc' },
    include: {
      items: {
        orderBy: { position: 'asc' },
        include: { version: { select: { payloadSha256: true } } },
      },
    },
  });
  if (!pack) return null;
  const items = pack.items.map((item) => ({
    position: item.position,
    contentId: item.contentId,
    contentVersion: item.contentVersion,
    payloadSha256: item.version.payloadSha256,
  }));
  const checksum = packChecksum(items);
  if (checksum !== pack.checksumSha256) throw new PackChecksumError();
  return {
    packId: pack.packId,
    packVersion: pack.packVersion,
    checksumSha256: pack.checksumSha256,
    totalBytes: pack.totalBytes,
    minAppVersion: pack.minAppVersion,
    items,
  };
}
