import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/data/memory/memory_repository.dart';
import 'package:little_genius/domain/profile.dart';
import 'package:little_genius/domain/progress_rules.dart';
import 'package:little_genius/features/home/catalog.dart';
import 'package:little_genius/features/parent/local_progress.dart';
import 'package:little_genius/features/parent/parent_screens.dart';
import 'package:little_genius/l10n/app_localizations.dart';
import 'package:little_genius/routing/providers.dart';
import 'package:little_genius/theme/app_theme.dart';

void main() {
  test('a quiet profile suggests one activity and hides counts', () {
    final view = describeLocalProgress(
      ageBand: '2-3',
      locale: 'en',
      events: const [],
      summaries: const [],
    );
    expect(view.completed, isEmpty);
    expect(view.categoriesTouched, isEmpty);
    expect(view.recent, isEmpty);
    expect(view.suggestion?.contentId, 'animal.elephant.001');
    expect(view.suggestion?.label, 'Elephant');
  });

  test('finished work, categories, recent activity, and one next activity', () {
    final elephantDone = _event(
      'e1',
      'animal.elephant.001',
      'completed',
      DateTime.utc(2026, 10, 2),
    );
    final elephantOpened = _event(
      'e2',
      'animal.elephant.001',
      'started',
      DateTime.utc(2026, 10, 1),
    );
    final view = describeLocalProgress(
      ageBand: '2-3',
      locale: 'hi',
      events: [elephantOpened, elephantDone],
      summaries: [
        ProgressSummary(
          profileId: 'child',
          categoryId: 'animals',
          startedCount: 1,
          completedCount: 1,
          lastActivityAt: elephantDone.occurredAt,
        ),
      ],
    );
    expect(view.completed.map((item) => item.label), ['हाथी']);
    expect(view.completed.single.label.contains('Elephant'), isFalse);
    expect(view.categoriesTouched, ['animals']);
    expect(view.recent.map((item) => item.eventType), ['completed', 'started']);
    expect(view.suggestion?.contentId, 'pair.daynight.001');
    expect(view.suggestion?.label, 'दिन और रात');
    expect(view.suggestion?.label.contains('Day'), isFalse);
  });

  test('a missing locale title is not replaced with English', () {
    const lessons = [
      LessonFacts(
        contentId: 'color.red.001',
        categoryId: 'colors',
        minMonths: 12,
        maxMonths: 60,
        locales: {'hi'},
        titles: {'hi': 'लाल'},
      ),
      LessonFacts(
        contentId: 'animal.elephant.001',
        categoryId: 'animals',
        minMonths: 12,
        maxMonths: 60,
        locales: {'en'},
        titles: {'en': 'Elephant'},
      ),
    ];
    final view = describeLocalProgress(
      ageBand: '2-3',
      locale: 'en',
      events: [
        _event('e1', 'color.red.001', 'completed', DateTime.utc(2026, 10, 3)),
      ],
      summaries: const [],
      lessons: lessons,
    );
    expect(view.completed.single.label, 'color.red.001');
    expect(view.suggestion?.contentId, 'animal.elephant.001');
    expect(view.suggestion?.label, 'Elephant');
  });

  test(
    'an opened activity is not the suggestion while another is untouched',
    () {
      final view = describeLocalProgress(
        ageBand: '1-2',
        locale: 'en',
        events: [
          _event(
            'e1',
            'animal.elephant.001',
            'started',
            DateTime.utc(2026, 10, 1),
          ),
        ],
        summaries: [
          ProgressSummary(
            profileId: 'child',
            categoryId: 'animals',
            startedCount: 1,
            completedCount: 0,
            lastActivityAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      );
      expect(view.completed, isEmpty);
      expect(view.suggestion?.contentId, 'color.red.001');
      expect(view.suggestion?.label, 'Red');
    },
  );

  test('nothing is suggested when every matching activity is finished', () {
    final lessons = [
      for (final lesson in knownLessons)
        if (lesson.contentId == 'animal.elephant.001' ||
            lesson.contentId == 'color.red.001')
          lesson,
    ];
    final view = describeLocalProgress(
      ageBand: '1-2',
      locale: 'en',
      events: [
        _event(
          'e1',
          'animal.elephant.001',
          'completed',
          DateTime.utc(2026, 10, 2),
        ),
        _event('e2', 'color.red.001', 'completed', DateTime.utc(2026, 10, 3)),
      ],
      summaries: const [],
      lessons: lessons,
    );
    expect(view.suggestion, isNull);
    expect(view.completed.map((item) => item.contentId), [
      'color.red.001',
      'animal.elephant.001',
    ]);
  });

  test('progress copy does not score, streak, or compare', () {
    const banned = [
      'streak',
      'score',
      'rank',
      'behind',
      'shame',
      'better than',
      'try harder',
      'diagnosis',
      'comparison',
    ];
    final english = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    const keys = [
      'progressOnDevice',
      'completedHeading',
      'categoriesHeading',
      'recentHeading',
      'suggestionHeading',
      'suggestionNone',
      'openedActivity',
      'noCategoryYet',
      'noRecent',
      'noProgress',
    ];
    for (final key in keys) {
      final value = (english[key] as String).toLowerCase();
      for (final word in banned) {
        expect(value.contains(word), isFalse, reason: '$key $word');
      }
    }
  });

  testWidgets('the progress page reads this profile on the device', (
    tester,
  ) async {
    final repository = MemoryLearningRepository();
    final profile = await repository.createProfile(
      const ProfileDraft(
        nickname: 'Asha',
        avatarId: 'star',
        ageBand: '2-3',
        preferredLocale: 'en',
        bilingualMode: false,
      ),
    );
    final other = await repository.createProfile(
      const ProfileDraft(
        nickname: 'Dev',
        avatarId: 'moon',
        ageBand: '4-5',
        preferredLocale: 'en',
        bilingualMode: false,
      ),
    );
    await repository.setActiveProfileId(profile.profileId);
    await repository.applyEvent(
      profileId: profile.profileId,
      categoryId: 'animals',
      event: _event(
        'asha-done',
        'animal.elephant.001',
        'completed',
        DateTime.utc(2026, 10, 4),
      ),
    );
    await repository.applyEvent(
      profileId: other.profileId,
      categoryId: 'numbers',
      event: _event(
        'dev-done',
        'count.birds.001',
        'completed',
        DateTime.utc(2026, 10, 5),
      ),
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-on-device')), findsOneWidget);
    expect(
      find.text('This list stays on this device. It is not uploaded.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('completed-animal.elephant.001')),
      findsOneWidget,
    );
    expect(find.text('Elephant'), findsWidgets);
    expect(find.byKey(const Key('category-touched-animals')), findsOneWidget);
    expect(find.text('Animals'), findsOneWidget);
    expect(find.byKey(const Key('recent-asha-done')), findsOneWidget);
    expect(find.text('Elephant · Finished'), findsOneWidget);
    expect(
      find.byKey(const Key('suggestion-pair.daynight.001')),
      findsOneWidget,
    );
    expect(find.text('Day and night'), findsOneWidget);
    expect(find.text('Three birds'), findsNothing);
    expect(find.textContaining('Started:'), findsNothing);
    expect(find.textContaining('Finished:'), findsNothing);
    expect(find.textContaining('streak'), findsNothing);
    expect(find.textContaining('score'), findsNothing);
  });
}

LearningEvent _event(
  String id,
  String contentId,
  String eventType,
  DateTime occurredAt,
) {
  return LearningEvent(
    eventId: id,
    contentId: contentId,
    contentVersion: 1,
    eventType: eventType,
    occurredAt: occurredAt,
  );
}

Widget _app(MemoryLearningRepository repository) {
  return ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: appTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProgressScreen(),
    ),
  );
}
