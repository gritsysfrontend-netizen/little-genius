import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/content/lesson_parser.dart';
import 'package:little_genius/content/widgets.dart';
import 'package:little_genius/l10n/app_localizations.dart';
import 'package:little_genius/theme/app_theme.dart';

void main() {
  final fixture = jsonDecode(
    File('../../infrastructure/fixtures/animal.elephant.001.json')
        .readAsStringSync(),
  );

  testWidgets('tap to learn shows the instruction and feedback', (
    tester,
  ) async {
    final parsed = parseLessonDocument(fixture);
    String? feedback;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return LessonRenderer(
              lesson: parsed,
              instruction: 'Tap the elephant',
              secondaryTitle: 'हाथी',
              feedback: feedback,
              imageBytes: null,
              imageLabel: 'Elephant',
              onTarget: () => setState(() => feedback = 'Great exploring!'),
              onHome: () {},
              onBack: () {},
              onPlay: () {},
              onPause: () {},
              onReplay: () {},
            );
          },
        ),
      ),
    );
    expect(find.text('Tap the elephant'), findsOneWidget);
    expect(find.text('हाथी'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tap-target')));
    await tester.pump();
    expect(find.text('Great exploring!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown interaction shows the fallback and does not throw', (
    tester,
  ) async {
    final hostile = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
    hostile['interaction'] = {'type': 'script'};
    final parsed = parseLessonDocument(hostile);
    expect(parsed, isA<UnsupportedLesson>());
    await tester.pumpWidget(
      _wrap(
        LessonRenderer(
          lesson: parsed,
          instruction: 'ignored',
          secondaryTitle: null,
          feedback: null,
          imageBytes: null,
          imageLabel: '',
          onTarget: () => fail('target'),
          onHome: () {},
          onBack: () {},
          onPlay: () {},
          onPause: () {},
          onReplay: () {},
        ),
      ),
    );
    expect(find.text('This activity is not available.'), findsOneWidget);
    expect(find.byKey(const Key('tap-target')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tamil chrome is used for the fallback', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LessonRenderer(
          lesson: const UnsupportedLesson('schema'),
          instruction: '',
          secondaryTitle: null,
          feedback: null,
          imageBytes: null,
          imageLabel: '',
          onTarget: () {},
          onHome: () {},
          onBack: () {},
          onPlay: () {},
          onPause: () {},
          onReplay: () {},
        ),
        const Locale('ta'),
      ),
    );
    expect(find.text('இந்தச் செயல்பாடு இப்போது இல்லை.'), findsOneWidget);
    expect(find.text('முகப்பு'), findsOneWidget);
  });
}

Widget _wrap(Widget child, [Locale locale = const Locale('en')]) {
  return MaterialApp(
    locale: locale,
    theme: appTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
