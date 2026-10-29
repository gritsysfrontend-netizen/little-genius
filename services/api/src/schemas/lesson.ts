import { z } from 'zod';

const id = z.string().regex(/^[a-z0-9._-]{1,80}$/);
const sha = z.string().regex(/^[a-f0-9]{64}$/);

const localization = z
  .object({
    title: z.string().min(1).max(80),
    instruction: z.string().min(1).max(160),
    feedbackCorrect: z.string().min(1).max(80),
    audio: z
      .object({
        instructionAssetId: id,
      })
      .strict()
      .optional(),
  })
  .strict();

const assetRef = z
  .object({
    assetId: id,
    mediaType: z.enum(['image', 'audio', 'sound_effect']),
    sha256: sha,
  })
  .strict();

const tapToLearn = z
  .object({
    type: z.literal('tap_to_learn'),
    targetAssetId: id,
    completionRule: z.literal('target_tapped'),
    retryPolicy: z.literal('unlimited'),
  })
  .strict();

export const lessonDocumentSchema = z
  .object({
    schemaVersion: z.literal('1.0'),
    contentId: id,
    contentVersion: z.number().int().min(1),
    categoryId: z.string().min(1).max(64),
    ageRange: z
      .object({
        minMonths: z.number().int().min(12).max(60),
        maxMonths: z.number().int().min(12).max(60),
      })
      .strict(),
    learningObjectives: z.array(z.string().min(1).max(64)).min(1),
    difficulty: z.number().int().min(1).max(5),
    estimatedDurationSeconds: z.number().int().min(10).max(600),
    localizations: z
      .object({
        en: localization.optional(),
        hi: localization.optional(),
        ta: localization.optional(),
      })
      .strict()
      .refine((value) => Boolean(value.en || value.hi || value.ta), {
        message: 'at least one localization',
      }),
    assets: z.array(assetRef),
    interaction: tapToLearn,
    accessibility: z
      .object({
        imageLabel: z
          .object({
            en: z.string().optional(),
            hi: z.string().optional(),
            ta: z.string().optional(),
          })
          .strict(),
        requiresAudio: z.boolean(),
      })
      .strict(),
  })
  .strict()
  .superRefine((doc, ctx) => {
    if (doc.ageRange.minMonths > doc.ageRange.maxMonths) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'age range is inverted' });
    }
    const known = new Set(doc.assets.map((asset) => asset.assetId));
    if (!known.has(doc.interaction.targetAssetId)) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'target asset is missing' });
    }
    for (const locale of Object.values(doc.localizations)) {
      const audioId = locale?.audio?.instructionAssetId;
      if (audioId && !known.has(audioId)) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'audio asset is missing' });
      }
    }
  });

export type LessonDocument = z.infer<typeof lessonDocumentSchema>;

export const manifestQuerySchema = z
  .object({
    locale: z.enum(['en', 'hi', 'ta']),
    ageBand: z.enum(['1-2', '2-3', '3-4', '4-5']),
    cursor: z.string().max(512).optional(),
  })
  .strict();

export const contentIdSchema = z.string().regex(/^[a-z0-9._-]{1,80}$/);
export const versionSchema = z.coerce.number().int().min(1);
