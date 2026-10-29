import { readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const skip = new Set([
  '.git',
  'node_modules',
  'build',
  '.dart_tool',
  'dist',
  'coverage',
]);

const rules = [
  {
    name: 'private-key',
    re: new RegExp(['-----BEGIN ', 'PRIVATE KEY-----'].join('')),
  },
  { name: 'aws-access-key', re: /AKIA[0-9A-Z]{16}/ },
  { name: 'github-token', re: /ghp_[A-Za-z0-9]{20,}/ },
  { name: 'github-pat', re: /github_pat_[A-Za-z0-9_]{20,}/ },
  { name: 'slack-token', re: /xox[baprs]-[A-Za-z0-9-]{10,}/ },
  { name: 'stripe-live', re: /sk_live_[A-Za-z0-9]{10,}/ },
];

function walk(dir, out) {
  for (const name of readdirSync(dir)) {
    if (skip.has(name)) continue;
    const full = path.join(dir, name);
    const info = statSync(full);
    if (info.isDirectory()) walk(full, out);
    else if (info.isFile() && info.size < 2_000_000) out.push(full);
  }
}

const files = [];
walk(root, files);
const hits = [];
for (const file of files) {
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch {
    continue;
  }
  if (text.includes('\0')) continue;
  const lines = text.split(/\r?\n/);
  lines.forEach((line, index) => {
    if (line.includes('local-dev-only-not-a-secret')) return;
    for (const rule of rules) {
      if (rule.re.test(line)) {
        hits.push(`${path.relative(root, file)}:${index + 1} ${rule.name}`);
      }
    }
  });
}

if (hits.length > 0) {
  console.error(hits.join('\n'));
  process.exit(1);
}
console.log(`secret scan ok (${files.length} files)`);
