import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/app.dart';
import 'package:little_genius/data/downloader.dart';
import 'package:little_genius/data/memory/memory_repository.dart';
import 'package:little_genius/domain/profile.dart';
import 'package:little_genius/features/common/app_status.dart';
import 'package:little_genius/features/common/status_message.dart';
import 'package:little_genius/features/home/home_screen.dart';
import 'package:little_genius/l10n/app_localizations.dart';
import 'package:little_genius/routing/providers.dart';
import 'package:little_genius/theme/app_theme.dart';
import 'package:little_genius/theme/contrast.dart';

void main() {
  test('session copy does not say the operating system stops play', () {
    final dangerous = RegExp(
      r'operating system|iOS will|Android will|Screen Time (will|stops|enforces)|locks the (phone|device)',
      caseSensitive: false,
    );
    for (final name in ['app_en.arb', 'app_hi.arb', 'app_ta.arb']) {
      final json = jsonDecode(
        File('lib/l10n/$name').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final entry in json.entries) {
        if (entry.value is! String) continue;
        expect(
          dangerous.hasMatch(entry.value as String),
          isFalse,
          reason: entry.key,
        );
      }
    }
    final english = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final body = english['sessionLimitBody'] as String;
    expect(body, contains('does not lock the phone'));
    expect(body.toLowerCase(), contains('not screen time'));
    expect(
      english['sessionEndedBody'],
      contains('did not turn off the device'),
    );
    expect(english['sessionPaused'], contains('does not control the phone'));
    expect(english.containsKey('sessionNotBuilt'), isFalse);
  });

  test('parent colors meet WCAG AA contrast', () {
    final theme = appTheme();
    expect(
      contrastRatio(theme.colorScheme.onSurface, theme.scaffoldBackgroundColor),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(theme.colorScheme.onPrimary, theme.colorScheme.primary),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('every status has visible copy and stays still', (tester) async {
    for (final status in AppStatus.values) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: StatusMessage(status: status)),
          ),
        ),
      );
      expect(find.byKey(Key('status-${status.name}')), findsOneWidget);
      final message = tester.widget<Text>(
        find.descendant(
          of: find.byKey(Key('status-${status.name}')),
          matching: find.byType(Text),
        ),
      );
      expect(message.data, isNotEmpty);
      final context = tester.element(find.byType(StatusMessage));
      expect(reduceMotionOf(context), isTrue);
      expect(tester.binding.transientCallbackCount, 0);
    }
  });

  testWidgets(
    'a grown-up can set a reminder and a finished reminder lets the child go home',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = MemoryLearningRepository();
      final profile = await repository.createProfile(
        const ProfileDraft(
          nickname: 'Asha',
          avatarId: 'star',
          ageBand: '3-4',
          preferredLocale: 'en',
          bilingualMode: false,
        ),
      );
      await repository.setActiveProfileId(profile.profileId);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      container.read(playReminderProvider.notifier).background();
      await tester.pump();
      expect(find.byKey(const Key('session-paused')), findsNothing);

      await container.read(playReminderProvider.notifier).choose(10);
      container.read(playReminderProvider.notifier).background();
      await tester.pump();
      expect(find.textContaining('does not control the phone'), findsOneWidget);
      await container.read(playReminderProvider.notifier).choose(null);
      await tester.pump();
      expect(find.byKey(const Key('session-paused')), findsNothing);

      await tester.tap(find.byKey(const Key('grown-ups')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('gate-answer')), '7');
      await tester.tap(find.byKey(const Key('gate-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Play reminder'), findsOneWidget);
      expect(
        find.text('Session limits are not in this version.'),
        findsNothing,
      );

      final orders = tester
          .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
          .map((widget) => (widget.order as NumericFocusOrder).order)
          .toList();
      expect(orders, [1, 2, 3, 4, 5]);
      Focus.of(tester.element(find.byKey(const Key('parent-language'))))
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.byKey(const Key('parent-downloads'))))
            .hasFocus,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('parent-session')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('session-limit-body')), findsOneWidget);
      expect(find.textContaining('not Screen Time'), findsOneWidget);
      await tester.tap(find.byKey(const Key('session-5')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('5 minutes'), findsOneWidget);
      expect(await repository.getSetting('session_limit_minutes'), '5');

      await tester.tap(find.byKey(const Key('home-button')));
      await tester.pump(const Duration(milliseconds: 400));
      container
          .read(playReminderProvider.notifier)
          .tick(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(find.text('Time for a rest'), findsOneWidget);
      expect(
        find.textContaining('did not turn off the device'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('rest-home')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Hello, Asha'), findsOneWidget);
    },
  );

  testWidgets('parent screens stay usable at text scale 2', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = MemoryLearningRepository();
    final profile = await repository.createProfile(
      const ProfileDraft(
        nickname: 'Asha',
        avatarId: 'star',
        ageBand: '3-4',
        preferredLocale: 'en',
        bilingualMode: false,
      ),
    );
    await repository.setActiveProfileId(profile.profileId);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('grown-ups')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('gate-answer')), '7');
    await tester.tap(find.byKey(const Key('gate-continue')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('parent-session')),
      400,
    );
    await tester.tap(find.byKey(const Key('parent-session')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('session-limit-body')), findsOneWidget);
  });
}

Widget _app(MemoryLearningRepository repository) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repository),
      byteSourceProvider.overrideWithValue(_OfflineSource()),
    ],
    child: const LittleGeniusApp(),
  );
}

class _OfflineSource implements ByteSource {
  @override
  Future<List<int>> get(Uri uri, DownloadCancelToken token) async {
    throw StateError('offline');
  }
}
