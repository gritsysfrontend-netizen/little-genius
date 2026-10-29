import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/content/lesson_parser.dart';
import 'package:little_genius/content/widgets.dart';
import 'package:little_genius/l10n/app_localizations.dart';
import 'package:little_genius/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('single choice retries a wrong tap and completes once', (
    tester,
  ) async {
    final counts = await _play(tester, 'color.red.001.json');
    await tester.tap(find.byKey(const Key('choice-blue')));
    await tester.pump();
    expect(counts.retried, 1);
    expect(counts.solved, 0);
    await tester.tap(find.byKey(const Key('choice-red')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('choice-red')));
    await tester.pump();
    expect(counts.solved, 1);
    expect(counts.retried, 1);
    expect(find.text('Red'), findsOneWidget);
  });

  testWidgets('choice labels stay in the selected locale', (tester) async {
    await _play(tester, 'color.red.001.json', locale: const Locale('hi'));
    expect(find.text('लाल'), findsWidgets);
    expect(find.text('Red'), findsNothing);
    expect(find.text('Blue'), findsNothing);
  });

  testWidgets('matching completes only when every pair matches', (
    tester,
  ) async {
    final counts = await _play(tester, 'pair.daynight.001.json');
    await tester.tap(find.byKey(const Key('prompt-sun')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-moon')));
    await tester.pump();
    expect(counts.retried, 1);
    expect(counts.solved, 0);
    await tester.tap(find.byKey(const Key('prompt-sun')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-sun')));
    await tester.pump();
    expect(counts.solved, 0);
    await tester.tap(find.byKey(const Key('prompt-moon')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-moon')));
    await tester.pump();
    expect(counts.solved, 1);
    expect(counts.retried, 1);
  });

  testWidgets('sorting retries a wrong bin and completes once', (tester) async {
    final counts = await _play(tester, 'sort.bigsmall.001.json');
    await tester.tap(find.byKey(const Key('item-house')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('bin-small')));
    await tester.pump();
    expect(counts.retried, 1);
    expect(counts.solved, 0);
    await tester.tap(find.byKey(const Key('item-house')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('bin-big')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('item-cup')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('bin-small')));
    await tester.pump();
    expect(counts.solved, 1);
    expect(counts.retried, 1);
  });

  testWidgets('counting completes only on the target', (tester) async {
    final counts = await _play(tester, 'count.birds.001.json');
    await tester.tap(find.byKey(const Key('count-less')));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('count-done')));
    await tester.pump();
    expect(counts.retried, 1);
    expect(counts.solved, 0);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('count-more')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('count-done')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('count-done')));
    await tester.pump();
    expect(counts.solved, 1);
    expect(counts.retried, 1);
  });

  testWidgets('sequencing ignores a step that is not next', (tester) async {
    final counts = await _play(tester, 'order.morning.001.json');
    await tester.tap(find.byKey(const Key('step-play')));
    await tester.pump();
    expect(counts.retried, 1);
    expect(counts.solved, 0);
    await tester.tap(find.byKey(const Key('step-wake')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('step-eat')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('step-play')));
    await tester.pump();
    expect(counts.solved, 1);
    expect(counts.retried, 1);
  });
}

class _Counts {
  int solved = 0;
  int retried = 0;
}

Future<_Counts> _play(
  WidgetTester tester,
  String file, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final parsed = parseLessonDocument(
    jsonDecode(File('../../infrastructure/fixtures/$file').readAsStringSync()),
  );
  expect(parsed, isA<SupportedLesson>());
  final counts = _Counts();
  await tester.pumpWidget(
    _wrap(
      LessonRenderer(
        lesson: parsed,
        locale: locale.languageCode,
        instruction: 'Instruction',
        secondaryTitle: null,
        feedback: null,
        imageBytes: null,
        imageLabel: '',
        onTarget: () => counts.solved += 1,
        onRetry: () => counts.retried += 1,
        onHome: () {},
        onBack: () {},
        onPlay: () {},
        onPause: () {},
        onReplay: () {},
      ),
      locale,
    ),
  );
  await tester.pump();
  return counts;
}

Widget _wrap(Widget child, Locale locale) {
  return MaterialApp(
    locale: locale,
    theme: appTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
