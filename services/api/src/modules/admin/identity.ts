import type { FastifyRequest } from 'fastify';
import { z } from 'zod';

export const staffRoles = [
  'author',
  'reviewer_education',
  'reviewer_language',
  'reviewer_rights',
  'publisher',
  'administrator',
] as const;

export type StaffRole = (typeof staffRoles)[number];

export type AccessClaims = {
  sub: string;
  aud: 'staff' | 'parent';
  amr: string[];
  roles: StaffRole[];
};

export interface IdentityProvider {
  verify(authorization: string | undefined): AccessClaims | null;
}

const claimsSchema = z
  .object({
    sub: z.string().regex(/^[A-Za-z0-9._:-]{1,80}$/),
    aud: z.enum(['staff', 'parent']),
    amr: z.array(z.string().min(1).max(40)).max(8).optional(),
    roles: z.array(z.enum(staffRoles)).max(staffRoles.length).optional(),
  })
  .strict();

/**
 * Unsigned tokens for tests and the local staff console.
 * A production identity provider is not wired. This double accepts only
 * `Bearer test.` plus base64url JSON, and only when the app is given this
 * provider. It stores no secret and does not call Cognito.
 */
export class TestIdentityProvider implements IdentityProvider {
  verify(authorization: string | undefined): AccessClaims | null {
    if (!authorization?.startsWith('Bearer test.')) return null;
    try {
      const json = Buffer.from(authorization.slice('Bearer test.'.length), 'base64url').toString(
        'utf8',
      );
      const parsed = claimsSchema.safeParse(JSON.parse(json));
      if (!parsed.success) return null;
      return {
        sub: parsed.data.sub,
        aud: parsed.data.aud,
        amr: parsed.data.amr ?? [],
        roles: parsed.data.roles ?? [],
      };
    } catch {
      return null;
    }
  }
}

export class DenyIdentityProvider implements IdentityProvider {
  verify(): null {
    return null;
  }
}

export function testAuthorization(input: {
  sub: string;
  aud?: 'staff' | 'parent';
  mfa?: boolean;
  roles?: StaffRole[];
}): string {
  const claims = {
    sub: input.sub,
    aud: input.aud ?? 'staff',
    amr: input.mfa === false ? [] : ['mfa'],
    roles: input.roles ?? [],
  };
  return `Bearer test.${Buffer.from(JSON.stringify(claims)).toString('base64url')}`;
}

declare module 'fastify' {
  interface FastifyRequest {
    staffClaims?: AccessClaims;
  }
}

export function staffClaims(request: FastifyRequest): AccessClaims {
  if (!request.staffClaims) {
    throw new Error('staff claims missing');
  }
  return request.staffClaims;
}
