import '../../domain/profile.dart';
import '../../domain/progress_rules.dart';

const uploadedFieldNames = [
  'nickname',
  'avatar',
  'age band',
  'language',
  'bilingual flag',
  'started and completed activities',
];

class UploadPlan {
  const UploadPlan({required this.clientProfileId, required this.body});

  final String clientProfileId;
  final Map<String, Object?> body;
}

class LocalSnapshot {
  const LocalSnapshot({
    required this.profileId,
    required this.eventIds,
    required this.outboxBodies,
  });

  final String profileId;
  final List<String> eventIds;
  final List<String> outboxBodies;

  /// Cancelling conversion returns the same device snapshot.
  LocalSnapshot afterCancel() => this;
}

/// Nothing is uploaded until consent is recorded and Cognito is configured.
/// The profile id is sent as clientProfileId so a retry does not create a second profile.
UploadPlan? buildAccountUpload({
  required bool consentGranted,
  required bool cognitoConfigured,
  required ChildProfile profile,
  required List<LearningEvent> events,
}) {
  if (!consentGranted || !cognitoConfigured) return null;
  return UploadPlan(
    clientProfileId: profile.profileId,
    body: {
      'clientProfileId': profile.profileId,
      'nickname': profile.nickname,
      'avatarId': profile.avatarId,
      'ageBand': profile.ageBand,
      'preferredLocale': profile.preferredLocale,
      'bilingualMode': profile.bilingualMode,
      'events': events.map((event) => event.toJson()).toList(),
    },
  );
}

class DeletionAttempt {
  const DeletionAttempt({required this.showsFinished, required this.message});

  final bool showsFinished;
  final String message;
}

DeletionAttempt requestDeletion({required bool online, String? serverStatus}) {
  if (!online) {
    return const DeletionAttempt(
      showsFinished: false,
      message: 'A network connection is required to finish deletion.',
    );
  }
  if (serverStatus == 'completed') {
    return const DeletionAttempt(
      showsFinished: true,
      message: 'Deletion finished.',
    );
  }
  return const DeletionAttempt(
    showsFinished: false,
    message: 'Deletion is not finished. A job is still waiting.',
  );
}
