import '../../domain/age_band.dart';
import '../../domain/progress_rules.dart';
import '../home/catalog.dart';

const recentActivityLimit = 5;

class ProgressActivity {
  const ProgressActivity({
    required this.contentId,
    required this.label,
    required this.categoryId,
    required this.occurredAt,
    required this.eventType,
    required this.eventId,
  });

  final String contentId;
  final String label;
  final String categoryId;
  final DateTime occurredAt;
  final String eventType;
  final String eventId;
}

class SuggestedActivity {
  const SuggestedActivity({
    required this.contentId,
    required this.label,
    required this.categoryId,
  });

  final String contentId;
  final String label;
  final String categoryId;
}

class LocalProgressView {
  const LocalProgressView({
    required this.completed,
    required this.categoriesTouched,
    required this.recent,
    required this.suggestion,
  });

  final List<ProgressActivity> completed;
  final List<String> categoriesTouched;
  final List<ProgressActivity> recent;
  final SuggestedActivity? suggestion;
}

/// A calm summary of one profile. Counts, streaks, and comparisons are not
/// part of the result. Titles come from the requested locale only.
LocalProgressView describeLocalProgress({
  required String ageBand,
  required String locale,
  required List<LearningEvent> events,
  required List<ProgressSummary> summaries,
  List<LessonFacts> lessons = knownLessons,
}) {
  final byId = {for (final lesson in lessons) lesson.contentId: lesson};
  final relevant =
      [
        for (final event in events)
          if (event.eventType == 'started' || event.eventType == 'completed')
            event,
      ]..sort((a, b) {
        final byTime = b.occurredAt.compareTo(a.occurredAt);
        if (byTime != 0) return byTime;
        final byContent = a.contentId.compareTo(b.contentId);
        if (byContent != 0) return byContent;
        return a.eventType.compareTo(b.eventType);
      });

  final completedIds = <String>{};
  final startedIds = <String>{};
  final completed = <ProgressActivity>[];
  for (final event in relevant) {
    if (event.eventType == 'started') startedIds.add(event.contentId);
    if (event.eventType != 'completed' || !completedIds.add(event.contentId)) {
      continue;
    }
    completed.add(_activity(event, locale, byId));
  }

  final touched = <String>{
    for (final row in summaries)
      if (row.startedCount > 0 ||
          row.completedCount > 0 ||
          row.lastActivityAt != null)
        row.categoryId,
  };
  final categories = [
    for (final id in categoryOrder)
      if (touched.contains(id)) id,
    for (final id in touched.toList()..sort())
      if (!categoryOrder.contains(id)) id,
  ];

  final recent = [
    for (final event in relevant.take(recentActivityLimit))
      _activity(event, locale, byId),
  ];

  return LocalProgressView(
    completed: completed,
    categoriesTouched: categories,
    recent: recent,
    suggestion: _suggestion(
      ageBand: ageBand,
      locale: locale,
      lessons: lessons,
      completedIds: completedIds,
      startedIds: startedIds,
    ),
  );
}

ProgressActivity _activity(
  LearningEvent event,
  String locale,
  Map<String, LessonFacts> byId,
) {
  return ProgressActivity(
    contentId: event.contentId,
    label: _label(byId[event.contentId], locale, event.contentId),
    categoryId: byId[event.contentId]?.categoryId ?? '',
    occurredAt: event.occurredAt,
    eventType: event.eventType,
    eventId: event.eventId,
  );
}

SuggestedActivity? _suggestion({
  required String ageBand,
  required String locale,
  required List<LessonFacts> lessons,
  required Set<String> completedIds,
  required Set<String> startedIds,
}) {
  final eligible = [
    for (final lesson in lessons)
      if (_offerable(lesson, ageBand, locale)) lesson,
  ];
  final fresh = eligible.where(
    (lesson) =>
        !completedIds.contains(lesson.contentId) &&
        !startedIds.contains(lesson.contentId),
  );
  final unfinished = eligible.where(
    (lesson) => !completedIds.contains(lesson.contentId),
  );
  final lesson = fresh.isNotEmpty
      ? fresh.first
      : unfinished.isEmpty
      ? null
      : unfinished.first;
  if (lesson == null) return null;
  final title = lesson.titles[locale];
  if (title == null || title.isEmpty) return null;
  return SuggestedActivity(
    contentId: lesson.contentId,
    label: title,
    categoryId: lesson.categoryId,
  );
}

bool _offerable(LessonFacts lesson, String ageBand, String locale) {
  final title = lesson.titles[locale];
  return lesson.locales.contains(locale) &&
      title != null &&
      title.isNotEmpty &&
      ageOverlaps(ageBand, lesson.minMonths, lesson.maxMonths);
}

String _label(LessonFacts? facts, String locale, String contentId) {
  if (facts == null || !facts.locales.contains(locale)) return contentId;
  final title = facts.titles[locale];
  if (title == null || title.isEmpty) return contentId;
  return title;
}
