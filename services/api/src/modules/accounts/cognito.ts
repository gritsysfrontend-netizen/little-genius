import { createHash } from 'node:crypto';
import type { AccessClaims, IdentityProvider } from '../admin/identity.js';

/**
 * Public Cognito settings only. There is no client secret in this object.
 * A user pool is not created by this repository.
 */
export type CognitoPublicConfig = {
  region: string;
  issuer: string;
  audience: string;
  hostedDomain: string;
  redirectUri: string;
  scopes: readonly ['openid'];
};

export function loadCognitoPublicConfig(
  env: NodeJS.ProcessEnv = process.env,
): CognitoPublicConfig | null {
  const issuer = env.COGNITO_ISSUER?.trim() ?? '';
  const audience = env.COGNITO_AUDIENCE?.trim() ?? '';
  const hostedDomain = env.COGNITO_HOSTED_DOMAIN?.trim().replace(/\/$/, '') ?? '';
  const redirectUri = env.COGNITO_REDIRECT_URI?.trim() ?? '';
  const region = env.COGNITO_REGION?.trim() || 'ap-south-1';
  if (!issuer || !audience || !hostedDomain || !redirectUri) return null;
  return {
    region,
    issuer,
    audience,
    hostedDomain,
    redirectUri,
    scopes: ['openid'],
  };
}

export function codeChallengeS256(verifier: string): string {
  return createHash('sha256').update(verifier).digest('base64url');
}

export function authorizationUrl(
  config: CognitoPublicConfig,
  input: { state: string; codeChallenge: string; redirectUri?: string },
): string {
  const url = new URL('/oauth2/authorize', config.hostedDomain);
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('client_id', config.audience);
  url.searchParams.set('redirect_uri', input.redirectUri ?? config.redirectUri);
  url.searchParams.set('scope', 'openid');
  url.searchParams.set('state', input.state);
  url.searchParams.set('code_challenge', input.codeChallenge);
  url.searchParams.set('code_challenge_method', 'S256');
  return url.toString();
}

/** Token exchange body for a public PKCE client. No client_secret parameter. */
export function tokenRequestBody(input: {
  clientId: string;
  code: string;
  codeVerifier: string;
  redirectUri: string;
}): string {
  const params = new URLSearchParams();
  params.set('grant_type', 'authorization_code');
  params.set('client_id', input.clientId);
  params.set('code', input.code);
  params.set('redirect_uri', input.redirectUri);
  params.set('code_verifier', input.codeVerifier);
  return params.toString();
}

/**
 * Fail closed. This build does not fetch a user-pool JWKS and does not accept
 * a Cognito access token. Tests use the unsigned test identity double.
 */
export class CognitoIdentityProvider implements IdentityProvider {
  constructor(private readonly config: CognitoPublicConfig) {}

  verify(_authorization: string | undefined): AccessClaims | null {
    void this.config;
    return null;
  }
}
