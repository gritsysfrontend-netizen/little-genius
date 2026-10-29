class LearningEvent {
  const LearningEvent({
    required this.eventId,
    required this.contentId,
    required this.contentVersion,
    required this.eventType,
    required this.occurredAt,
    this.durationBucket,
  });

  final String eventId;
  final String contentId;
  final int contentVersion;
  final String eventType;
  final DateTime occurredAt;
  final String? durationBucket;

  Map<String, Object?> toJson() {
    return {
      'eventId': eventId,
      'contentId': contentId,
      'contentVersion': contentVersion,
      'eventType': eventType,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      if (durationBucket != null) 'durationBucket': durationBucket,
    };
  }

  static LearningEvent fromJson(Map<String, Object?> json) {
    return LearningEvent(
      eventId: json['eventId']! as String,
      contentId: json['contentId']! as String,
      contentVersion: json['contentVersion']! as int,
      eventType: json['eventType']! as String,
      occurredAt: DateTime.parse(json['occurredAt']! as String),
      durationBucket: json['durationBucket'] as String?,
    );
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.profileId,
    required this.categoryId,
    required this.startedCount,
    required this.completedCount,
    required this.lastActivityAt,
  });

  final String profileId;
  final String categoryId;
  final int startedCount;
  final int completedCount;
  final DateTime? lastActivityAt;

  ProgressSummary copyWith({
    int? startedCount,
    int? completedCount,
    DateTime? lastActivityAt,
  }) {
    return ProgressSummary(
      profileId: profileId,
      categoryId: categoryId,
      startedCount: startedCount ?? this.startedCount,
      completedCount: completedCount ?? this.completedCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

class ProgressDecision {
  const ProgressDecision({required this.insertEvent, required this.summary});

  final bool insertEvent;
  final ProgressSummary summary;
}

String durationBucketFor(Duration elapsed) {
  if (elapsed < const Duration(minutes: 1)) return 'lt_1m';
  if (elapsed <= const Duration(minutes: 5)) return 'm1_to_5';
  return 'gt_5m';
}

/// One started and one completed event are kept per content version.
/// A repeated event id does not change counts.
ProgressDecision decideProgress({
  required String profileId,
  required String categoryId,
  required ProgressSummary? current,
  required List<LearningEvent> existing,
  required LearningEvent event,
}) {
  final summary =
      current ??
      ProgressSummary(
        profileId: profileId,
        categoryId: categoryId,
        startedCount: 0,
        completedCount: 0,
        lastActivityAt: null,
      );
  final duplicateId = existing.any((item) => item.eventId == event.eventId);
  final sameKind = existing.any(
    (item) =>
        item.eventType == event.eventType &&
        item.contentId == event.contentId &&
        item.contentVersion == event.contentVersion,
  );
  if (duplicateId || sameKind) {
    return ProgressDecision(insertEvent: false, summary: summary);
  }
  final next = event.eventType == 'completed'
      ? summary.copyWith(
          completedCount: summary.completedCount + 1,
          lastActivityAt: event.occurredAt,
        )
      : summary.copyWith(
          startedCount: summary.startedCount + 1,
          lastActivityAt: event.occurredAt,
        );
  return ProgressDecision(insertEvent: true, summary: next);
}
