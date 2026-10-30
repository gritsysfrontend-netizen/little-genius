export type AppConfig = {
  assetSigningKey: string;
  publicBaseUrl: string;
  fixtureDir: string;
  schemaPath: string;
  rateManifest: number;
  rateLesson: number;
  rateAsset: number;
  assetUrlTtlSeconds: number;
  host: string;
  port: number;
};

function numberEnv(value: string | undefined, fallback: number): number {
  if (value === undefined || value === '') return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error('expected a positive integer environment value');
  }
  return parsed;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const assetSigningKey = env.ASSET_SIGNING_KEY;
  if (!assetSigningKey) {
    throw new Error('ASSET_SIGNING_KEY is required');
  }
  return {
    assetSigningKey,
    publicBaseUrl: (env.PUBLIC_BASE_URL ?? 'http://127.0.0.1:3000').replace(/\/$/, ''),
    fixtureDir: env.FIXTURE_DIR ?? '',
    schemaPath: env.CONTENT_SCHEMA_PATH ?? '',
    rateManifest: numberEnv(env.RATE_LIMIT_MANIFEST, 60),
    rateLesson: numberEnv(env.RATE_LIMIT_LESSON, 120),
    rateAsset: numberEnv(env.RATE_LIMIT_ASSET, 120),
    assetUrlTtlSeconds: numberEnv(env.ASSET_URL_TTL_SECONDS, 300),
    host: env.HOST ?? '127.0.0.1',
    port: numberEnv(env.PORT, 3000),
  };
}
