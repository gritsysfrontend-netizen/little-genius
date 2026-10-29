const imageMaxBytes = 1_048_576;
const audioMaxBytes = 2_097_152;

const blockedDeclared = new Set([
  'image/svg+xml',
  'text/html',
  'application/xhtml+xml',
  'text/javascript',
  'application/javascript',
  'text/ecmascript',
  'application/ecmascript',
]);

export type UploadInspection =
  | {
      ok: true;
      mediaType: 'image' | 'audio';
      contentType: 'image/jpeg' | 'image/png' | 'image/webp' | 'audio/mpeg' | 'audio/aac';
    }
  | { ok: false; reason: 'blocked' | 'mismatch' | 'rejected' | 'too_large' };

export function declaredMediaType(header: string | undefined): string {
  return (header ?? '').split(';')[0]!.trim().toLowerCase();
}

export function inspectUpload(bytes: Buffer, declared: string): UploadInspection {
  if (bytes.length === 0 || blockedDeclared.has(declared) || containsBlockedMarkup(bytes)) {
    return { ok: false, reason: 'blocked' };
  }
  const sniffed = sniff(bytes);
  if (!sniffed) return { ok: false, reason: 'rejected' };
  if (!declaredMatches(declared, sniffed)) return { ok: false, reason: 'mismatch' };
  const mediaType = sniffed.startsWith('image/') ? 'image' : 'audio';
  const max = mediaType === 'image' ? imageMaxBytes : audioMaxBytes;
  if (bytes.length > max) return { ok: false, reason: 'too_large' };
  const contentType = declared === 'audio/mp4' ? 'audio/aac' : sniffed;
  return { ok: true, mediaType, contentType };
}

function declaredMatches(
  declared: string,
  sniffed: 'image/jpeg' | 'image/png' | 'image/webp' | 'audio/mpeg' | 'audio/aac',
): boolean {
  if (declared === sniffed) return true;
  return sniffed === 'audio/aac' && declared === 'audio/mp4';
}

function sniff(
  bytes: Buffer,
): 'image/jpeg' | 'image/png' | 'image/webp' | 'audio/mpeg' | 'audio/aac' | null {
  if (isPng(bytes)) return 'image/png';
  if (isJpeg(bytes)) return 'image/jpeg';
  if (isWebp(bytes)) return 'image/webp';
  if (isAac(bytes)) return 'audio/aac';
  if (isMpeg(bytes)) return 'audio/mpeg';
  return null;
}

function containsBlockedMarkup(bytes: Buffer): boolean {
  const text = bytes.toString('latin1').toLowerCase();
  return (
    text.includes('<svg') ||
    text.includes('<script') ||
    text.includes('<html') ||
    text.includes('<!doctype html') ||
    text.includes('javascript:')
  );
}

function isPng(bytes: Buffer): boolean {
  return (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  );
}

function isJpeg(bytes: Buffer): boolean {
  return bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
}

function isWebp(bytes: Buffer): boolean {
  return (
    bytes.length >= 12 &&
    bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
    bytes.subarray(8, 12).toString('ascii') === 'WEBP'
  );
}

function isMpeg(bytes: Buffer): boolean {
  if (bytes.length >= 3 && bytes.subarray(0, 3).toString('ascii') === 'ID3') return true;
  if (bytes.length < 2 || bytes[0] !== 0xff || !bytes[1]) return false;
  const layer = (bytes[1] >> 1) & 0x03;
  return (bytes[1] & 0xe0) === 0xe0 && layer !== 0;
}

function isAac(bytes: Buffer): boolean {
  if (
    bytes.length >= 2 &&
    bytes[0] === 0xff &&
    bytes[1] !== undefined &&
    (bytes[1] & 0xf6) === 0xf0
  ) {
    return true;
  }
  if (bytes.length < 12 || bytes.subarray(4, 8).toString('ascii') !== 'ftyp') return false;
  const head = bytes.subarray(0, Math.min(bytes.length, 64)).toString('latin1');
  if (head.includes('avc1') || head.includes('hvc1')) return false;
  return bytes.subarray(8, 12).toString('ascii') === 'M4A ' || head.includes('mp4a');
}
