import { readFileSync } from 'node:fs';
import path from 'node:path';
import { parse } from 'yaml';

const file = path.join(import.meta.dirname, '../openapi/openapi.yaml');
const document = parse(readFileSync(file, 'utf8'));
const ids = [];
for (const item of Object.values(document.paths ?? {})) {
  if (!item || typeof item !== 'object') continue;
  for (const operation of Object.values(item)) {
    if (operation && typeof operation === 'object' && operation.operationId) {
      ids.push(operation.operationId);
    }
  }
}

const expected = [
  'getHealth',
  'getReady',
  'getContentManifest',
  'getContentVersionPointer',
  'getLessonDocument',
  'getAssetDescriptor',
  'listProfiles',
  'createProfile',
  'updateProfile',
  'deleteProfile',
  'syncEvents',
  'getProgress',
];

const missing = expected.filter((id) => !ids.includes(id));
const extra = ids.filter((id) => !expected.includes(id));
if (missing.length > 0 || extra.length > 0 || ids.length !== expected.length) {
  console.error(JSON.stringify({ missing, extra, found: ids }, null, 2));
  process.exit(1);
}

console.log(`openapi inventory ok (${ids.length} operations)`);
