import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  CognitoIdentityProvider,
  authorizationUrl,
  codeChallengeS256,
  loadCognitoPublicConfig,
  tokenRequestBody,
} from '../src/modules/accounts/cognito.js';

const publicConfig = {
  region: 'ap-south-1',
  issuer: 'https://cognito-idp.ap-south-1.amazonaws.com/pool-example',
  audience: 'public-client-id-placeholder',
  hostedDomain: 'https://auth.example.invalid',
  redirectUri: 'littlegenius://oidc',
  scopes: ['openid'] as const,
};

test('cognito settings are absent until every public value is set', () => {
  assert.equal(loadCognitoPublicConfig({}), null);
  assert.equal(
    loadCognitoPublicConfig({
      COGNITO_CLIENT_SECRET: 'do-not-keep-this',
      COGNITO_AUDIENCE: 'public-client-id-placeholder',
    }),
    null,
  );
  const loaded = loadCognitoPublicConfig({
    COGNITO_REGION: 'ap-south-1',
    COGNITO_ISSUER: publicConfig.issuer,
    COGNITO_AUDIENCE: publicConfig.audience,
    COGNITO_HOSTED_DOMAIN: publicConfig.hostedDomain,
    COGNITO_REDIRECT_URI: publicConfig.redirectUri,
    COGNITO_CLIENT_SECRET: 'do-not-keep-this',
  });
  assert.ok(loaded);
  assert.equal('clientSecret' in (loaded ?? {}), false);
  assert.equal(JSON.stringify(loaded).includes('do-not-keep-this'), false);
});

test('the authorize url and token body use PKCE and no client secret', () => {
  const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
  const challenge = codeChallengeS256(verifier);
  assert.equal(challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  const url = authorizationUrl(publicConfig, { state: 'state-1', codeChallenge: challenge });
  assert.match(url, /response_type=code/);
  assert.match(url, /code_challenge_method=S256/);
  assert.equal(url.includes('client_secret'), false);
  assert.equal(url.includes('do-not-keep-this'), false);
  const body = tokenRequestBody({
    clientId: publicConfig.audience,
    code: 'auth-code',
    codeVerifier: verifier,
    redirectUri: publicConfig.redirectUri,
  });
  assert.match(body, /grant_type=authorization_code/);
  assert.equal(body.includes('client_secret'), false);
  const provider = new CognitoIdentityProvider(publicConfig);
  assert.equal(provider.verify('Bearer eyJhbGciOiJSUzI1NiJ9.e30.sig'), null);
});
