import { readFileSync } from 'node:fs';
import path from 'node:path';
import { parse } from 'yaml';

const dir = path.join(import.meta.dirname, '../openapi');

function operationIds(fileName) {
  const document = parse(readFileSync(path.join(dir, fileName), 'utf8'));
  const ids = [];
  for (const item of Object.values(document.paths ?? {})) {
    if (!item || typeof item !== 'object') continue;
    for (const operation of Object.values(item)) {
      if (operation && typeof operation === 'object' && operation.operationId) {
        ids.push(operation.operationId);
      }
    }
  }
  return ids;
}

function expectIds(label, found, expected) {
  const missing = expected.filter((id) => !found.includes(id));
  const extra = found.filter((id) => !expected.includes(id));
  if (missing.length > 0 || extra.length > 0 || found.length !== expected.length) {
    console.error(JSON.stringify({ label, missing, extra, found }, null, 2));
    process.exit(1);
  }
  console.log(`${label} inventory ok (${found.length} operations)`);
}

const publicExpected = [
  'getHealth',
  'getReady',
  'getContentManifest',
  'getContentPack',
  'getContentVersionPointer',
  'getLessonDocument',
  'getAssetDescriptor',
  'listProfiles',
  'createProfile',
  'updateProfile',
  'deleteProfile',
  'syncEvents',
  'getProgress',
  'recordConsent',
  'exportAccount',
  'deleteAccount',
  'getPrivacyRequest',
];

const adminExpected = [
  'listDrafts',
  'createDraft',
  'getDraft',
  'updateDraft',
  'uploadAsset',
  'reviewEducation',
  'reviewRights',
  'reviewLanguage',
  'publishDraft',
  'unpublishContent',
  'listAudit',
];

const publicIds = operationIds('openapi.yaml');
const adminIds = operationIds('admin.yaml');
expectIds('public openapi', publicIds, publicExpected);
expectIds('admin openapi', adminIds, adminExpected);
const overlap = publicIds.filter((id) => adminIds.includes(id));
if (overlap.length > 0) {
  console.error(JSON.stringify({ overlap }, null, 2));
  process.exit(1);
}
