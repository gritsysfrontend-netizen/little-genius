import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../fixtures');
const lesson = JSON.parse(readFileSync(path.join(root, 'animal.elephant.001.json'), 'utf8'));
const checksums = JSON.parse(readFileSync(path.join(root, 'checksums.json'), 'utf8'));

const payloadSha = sha256(canonicalJson(lesson));
if (payloadSha !== checksums.payloadSha256) {
  throw new Error(`payload sha256 mismatch: ${payloadSha}`);
}

for (const asset of lesson.assets) {
  const recorded = checksums.assets[asset.assetId];
  if (!recorded || recorded.sha256 !== asset.sha256) {
    throw new Error(`checksum record missing for ${asset.assetId}`);
  }
  const bytes = readFileSync(path.join(root, recorded.file));
  const actual = sha256(bytes);
  if (actual !== asset.sha256 || bytes.length !== recorded.bytes) {
    throw new Error(`file hash mismatch for ${asset.assetId}`);
  }
}

console.log(`ok ${lesson.contentId} payload ${payloadSha}`);

function sha256(bytes) {
  return createHash('sha256').update(bytes).digest('hex');
}

function canonicalJson(value) {
  return stringify(value);
}

function stringify(value) {
  if (value === null) return 'null';
  if (typeof value === 'string') return JSON.stringify(value);
  if (typeof value === 'number') return JSON.stringify(value);
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  if (Array.isArray(value)) return `[${value.map((item) => stringify(item)).join(',')}]`;
  if (typeof value === 'object') {
    const keys = Object.keys(value).sort();
    return `{${keys.map((key) => `${JSON.stringify(key)}:${stringify(value[key])}`).join(',')}}`;
  }
  throw new Error('unsupported json value');
}
