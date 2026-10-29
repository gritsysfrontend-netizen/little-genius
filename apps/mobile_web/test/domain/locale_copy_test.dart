import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/domain/locale_copy.dart';

void main() {
  const copies = {
    'en': LocalizedCopy(
      title: 'Elephant',
      instruction: 'Tap',
      feedbackCorrect: 'Yes',
    ),
    'hi': LocalizedCopy(
      title: 'हाथी',
      instruction: 'टैप',
      feedbackCorrect: 'अच्छा',
    ),
    'ta': LocalizedCopy(
      title: 'யானை',
      instruction: 'தொடு',
      feedbackCorrect: 'நன்று',
    ),
  };

  test('missing locale does not fall back to English', () {
    expect(
      resolveCopy(localizations: copies, locale: 'fr', bilingual: true),
      isNull,
    );
    expect(
      resolveCopy(
        localizations: {'hi': copies['hi']!},
        locale: 'en',
        bilingual: false,
      ),
      isNull,
    );
  });

  test(
    'bilingual secondary is the next available locale in en, hi, ta order',
    () {
      final english = resolveCopy(
        localizations: copies,
        locale: 'en',
        bilingual: true,
      );
      expect(english!.secondaryLocale, 'hi');
      expect(english.secondary!.title, 'हाथी');

      final hindi = resolveCopy(
        localizations: copies,
        locale: 'hi',
        bilingual: true,
      );
      expect(hindi!.secondaryLocale, 'en');

      final tamil = resolveCopy(
        localizations: copies,
        locale: 'ta',
        bilingual: true,
      );
      expect(tamil!.secondaryLocale, 'en');

      final hindiOnly = resolveCopy(
        localizations: {'hi': copies['hi']!, 'ta': copies['ta']!},
        locale: 'hi',
        bilingual: true,
      );
      expect(hindiOnly!.secondaryLocale, 'ta');

      final off = resolveCopy(
        localizations: copies,
        locale: 'ta',
        bilingual: false,
      );
      expect(off!.secondary, isNull);
    },
  );
}
