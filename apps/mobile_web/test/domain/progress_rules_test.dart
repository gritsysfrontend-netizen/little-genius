import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/domain/progress_rules.dart';

LearningEvent event(String id, String type, {int version = 1, String? bucket}) {
  return LearningEvent(
    eventId: id,
    contentId: 'animal.elephant.001',
    contentVersion: version,
    eventType: type,
    occurredAt: DateTime.utc(2026, 10, 29, 12),
    durationBucket: bucket,
  );
}

void main() {
  test('started and completed are kept once per content version', () {
    final started = decideProgress(
      profileId: 'p',
      categoryId: 'animals',
      current: null,
      existing: const [],
      event: event('a', 'started'),
    );
    expect(started.insertEvent, isTrue);
    expect(started.summary.startedCount, 1);

    final again = decideProgress(
      profileId: 'p',
      categoryId: 'animals',
      current: started.summary,
      existing: [event('a', 'started')],
      event: event('b', 'started'),
    );
    expect(again.insertEvent, isFalse);
    expect(again.summary.startedCount, 1);

    final completed = decideProgress(
      profileId: 'p',
      categoryId: 'animals',
      current: started.summary,
      existing: [event('a', 'started')],
      event: event('c', 'completed', bucket: 'lt_1m'),
    );
    expect(completed.insertEvent, isTrue);
    expect(completed.summary.completedCount, 1);

    final duplicate = decideProgress(
      profileId: 'p',
      categoryId: 'animals',
      current: completed.summary,
      existing: [event('a', 'started'), event('c', 'completed')],
      event: event('c', 'completed'),
    );
    expect(duplicate.insertEvent, isFalse);
    expect(duplicate.summary.completedCount, 1);
  });

  test('a new content version can start again', () {
    final decision = decideProgress(
      profileId: 'p',
      categoryId: 'animals',
      current: const ProgressSummary(
        profileId: 'p',
        categoryId: 'animals',
        startedCount: 1,
        completedCount: 1,
        lastActivityAt: null,
      ),
      existing: [event('a', 'started'), event('c', 'completed')],
      event: event('d', 'started', version: 2),
    );
    expect(decision.insertEvent, isTrue);
    expect(decision.summary.startedCount, 2);
  });

  test('duration buckets', () {
    expect(durationBucketFor(const Duration(seconds: 59)), 'lt_1m');
    expect(durationBucketFor(const Duration(minutes: 1)), 'm1_to_5');
    expect(durationBucketFor(const Duration(minutes: 5)), 'm1_to_5');
    expect(durationBucketFor(const Duration(minutes: 5, seconds: 1)), 'gt_5m');
  });
}
