import { z } from 'zod';

const id = z.string().regex(/^[a-z0-9._-]{1,80}$/);
const sha = z.string().regex(/^[a-f0-9]{64}$/);

const localization = z
  .object({
    title: z.string().min(1).max(80),
    instruction: z.string().min(1).max(160),
    feedbackCorrect: z.string().min(1).max(80),
    feedbackRetry: z.string().min(1).max(80).optional(),
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

const localeText = z
  .object({
    en: z.string().min(1).max(40).optional(),
    hi: z.string().min(1).max(40).optional(),
    ta: z.string().min(1).max(40).optional(),
  })
  .strict()
  .refine((value) => Boolean(value.en || value.hi || value.ta), {
    message: 'label needs a locale',
  });

const labeledChoice = z
  .object({
    id,
    label: localeText,
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

const singleChoice = z
  .object({
    type: z.literal('single_choice'),
    completionRule: z.literal('answer_selected'),
    retryPolicy: z.literal('unlimited'),
    answerId: id,
    choices: z.array(labeledChoice).min(2).max(4),
  })
  .strict();

const matching = z
  .object({
    type: z.literal('matching'),
    completionRule: z.literal('all_pairs_matched'),
    retryPolicy: z.literal('unlimited'),
    pairs: z
      .array(
        z
          .object({
            id,
            prompt: localeText,
            match: localeText,
          })
          .strict(),
      )
      .min(2)
      .max(4),
  })
  .strict();

const sorting = z
  .object({
    type: z.literal('sorting'),
    completionRule: z.literal('each_item_sorted'),
    retryPolicy: z.literal('unlimited'),
    bins: z.array(labeledChoice).min(2).max(3),
    items: z
      .array(
        z
          .object({
            id,
            label: localeText,
            binId: id,
          })
          .strict(),
      )
      .min(2)
      .max(4),
  })
  .strict();

const counting = z
  .object({
    type: z.literal('counting'),
    completionRule: z.literal('count_matches'),
    retryPolicy: z.literal('unlimited'),
    targetCount: z.number().int().min(1).max(10),
    maxCount: z.number().int().min(1).max(10),
  })
  .strict();

const sequencing = z
  .object({
    type: z.literal('sequencing'),
    completionRule: z.literal('order_matches'),
    retryPolicy: z.literal('unlimited'),
    steps: z.array(labeledChoice).min(2).max(6),
  })
  .strict();

const interaction = z.discriminatedUnion('type', [
  tapToLearn,
  singleChoice,
  matching,
  sorting,
  counting,
  sequencing,
]);

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
    interaction,
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
    const locales = new Set(
      (['en', 'hi', 'ta'] as const).filter((code) => doc.localizations[code]),
    );
    const covers = (label: { en?: string; hi?: string; ta?: string }) =>
      [...locales].every((code) => Boolean(label[code]));
    const unique = (ids: string[], message: string) => {
      if (new Set(ids).size !== ids.length) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, message });
      }
    };
    if (doc.interaction.type !== 'tap_to_learn') {
      for (const locale of Object.values(doc.localizations)) {
        if (locale && !locale.feedbackRetry) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: 'retry feedback is missing',
          });
        }
      }
    }
    switch (doc.interaction.type) {
      case 'tap_to_learn':
        if (!known.has(doc.interaction.targetAssetId)) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'target asset is missing' });
        }
        break;
      case 'single_choice': {
        const ids = doc.interaction.choices.map((choice) => choice.id);
        unique(ids, 'choice ids repeat');
        if (!ids.includes(doc.interaction.answerId)) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'answer is not a choice' });
        }
        if (doc.interaction.choices.some((choice) => !covers(choice.label))) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: 'choice label is missing a locale',
          });
        }
        break;
      }
      case 'matching': {
        unique(
          doc.interaction.pairs.map((pair) => pair.id),
          'pair ids repeat',
        );
        if (doc.interaction.pairs.some((pair) => !covers(pair.prompt) || !covers(pair.match))) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'pair label is missing a locale' });
        }
        break;
      }
      case 'sorting': {
        const bins = doc.interaction.bins.map((bin) => bin.id);
        unique(bins, 'bin ids repeat');
        unique(
          doc.interaction.items.map((item) => item.id),
          'item ids repeat',
        );
        if (doc.interaction.items.some((item) => !bins.includes(item.binId))) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'item bin is missing' });
        }
        if (
          doc.interaction.bins.some((bin) => !covers(bin.label)) ||
          doc.interaction.items.some((item) => !covers(item.label))
        ) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'sort label is missing a locale' });
        }
        break;
      }
      case 'counting':
        if (doc.interaction.maxCount < doc.interaction.targetCount) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'count range is inverted' });
        }
        break;
      case 'sequencing':
        unique(
          doc.interaction.steps.map((step) => step.id),
          'step ids repeat',
        );
        if (doc.interaction.steps.some((step) => !covers(step.label))) {
          ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'step label is missing a locale' });
        }
        break;
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
