import { createHmac, timingSafeEqual } from 'node:crypto';

export function signAssetUrl(
  publicBaseUrl: string,
  assetId: string,
  expiresAt: number,
  key: string,
): string {
  const sig = signature(assetId, expiresAt, key);
  const url = new URL(`${publicBaseUrl}/api/v1/assets/${encodeURIComponent(assetId)}/bytes`);
  url.searchParams.set('exp', String(expiresAt));
  url.searchParams.set('sig', sig);
  return url.toString();
}

export function verifyAssetSignature(
  assetId: string,
  exp: string,
  sig: string,
  key: string,
  nowSeconds: number,
): boolean {
  if (!/^\d+$/.test(exp) || !/^[a-f0-9]{64}$/.test(sig)) return false;
  const expiresAt = Number(exp);
  if (expiresAt < nowSeconds) return false;
  const expected = signature(assetId, expiresAt, key);
  const left = Buffer.from(expected);
  const right = Buffer.from(sig);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

function signature(assetId: string, expiresAt: number, key: string): string {
  return createHmac('sha256', key).update(`${assetId}.${expiresAt}`).digest('hex');
}
