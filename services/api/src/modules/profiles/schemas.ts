import { z } from 'zod';

/**
 * Frozen Phase 5 shapes. The Phase 2 server does not mount these routes.
 * Local profiles are stored only on the device.
 */

const nickname = z.string().min(1).max(24);
const avatarId = z.enum(['star', 'sun', 'leaf', 'moon', 'bird', 'fish']);
const ageBand = z.enum(['1-2', '2-3', '3-4', '4-5']);
const locale = z.enum(['en', 'hi', 'ta']);

export const profileCreateSchema = z
  .object({
    clientProfileId: z.string().uuid(),
    nickname,
    avatarId,
    ageBand,
    preferredLocale: locale,
    bilingualMode: z.boolean(),
  })
  .strict();

export const profilePatchSchema = z
  .object({
    nickname: nickname.optional(),
    avatarId: avatarId.optional(),
    ageBand: ageBand.optional(),
    preferredLocale: locale.optional(),
    bilingualMode: z.boolean().optional(),
  })
  .strict();

export const childProfileSchema = z
  .object({
    profileId: z.string().uuid(),
    nickname,
    avatarId,
    ageBand,
    preferredLocale: locale,
    bilingualMode: z.boolean(),
    revision: z.number().int().min(1),
  })
  .strict();

export const learningEventSchema = z
  .object({
    eventId: z.string().uuid(),
    contentId: z.string().regex(/^[a-z0-9._-]{1,80}$/),
    contentVersion: z.number().int().min(1),
    eventType: z.enum(['started', 'completed']),
    occurredAt: z.string().datetime(),
    durationBucket: z.enum(['lt_1m', 'm1_to_5', 'gt_5m']).optional(),
  })
  .strict();

export const eventBatchSchema = z
  .object({
    events: z.array(learningEventSchema).min(1).max(50),
  })
  .strict();
