class ResolvedCopy {
  const ResolvedCopy({
    required this.primaryLocale,
    required this.primary,
    this.secondaryLocale,
    this.secondary,
  });

  final String primaryLocale;
  final LocalizedCopy primary;
  final String? secondaryLocale;
  final LocalizedCopy? secondary;
}

class LocalizedCopy {
  const LocalizedCopy({
    required this.title,
    required this.instruction,
    required this.feedbackCorrect,
    this.instructionAssetId,
  });

  final String title;
  final String instruction;
  final String feedbackCorrect;
  final String? instructionAssetId;
}

const localeOrder = ['en', 'hi', 'ta'];

/// Returns null when the selected locale is missing. There is no silent English fallback.
ResolvedCopy? resolveCopy({
  required Map<String, LocalizedCopy> localizations,
  required String locale,
  required bool bilingual,
}) {
  final primary = localizations[locale];
  if (primary == null) return null;
  LocalizedCopy? secondary;
  String? secondaryLocale;
  if (bilingual) {
    for (final code in localeOrder) {
      if (code == locale) continue;
      final copy = localizations[code];
      if (copy != null) {
        secondary = copy;
        secondaryLocale = code;
        break;
      }
    }
  }
  return ResolvedCopy(
    primaryLocale: locale,
    primary: primary,
    secondaryLocale: secondaryLocale,
    secondary: secondary,
  );
}
