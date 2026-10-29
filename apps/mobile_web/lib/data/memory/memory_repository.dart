import '../../domain/ids.dart';
import '../../domain/profile.dart';
import '../../domain/progress_rules.dart';
import '../learning_repository.dart';
import '../profile_factory.dart';
import '../records.dart';

/// In-memory store used by widget tests and as the reference for both drivers.
class MemoryLearningRepository implements LearningRepository {
  final Map<String, ChildProfile> _profiles = {};
  final Map<String, String> _settings = {};
  String? _active;
  final Map<String, StoredDocument> _documents = {};
  final Map<String, StoredBlob> _blobs = {};
  final Map<String, LearningEvent> _events = {};
  final Map<String, ProgressSummary> _progress = {};
  final List<OutboxEntry> _outbox = [];
  var _closed = false;

  void _check() {
    if (_closed) throw StateError('closed');
  }

  @override
  Future<ChildProfile> createProfile(ProfileDraft draft) async {
    _check();
    final profile = profileFromDraft(draft);
    _profiles[profile.profileId] = profile;
    return profile;
  }

  @override
  Future<ChildProfile?> getProfile(String profileId) async {
    _check();
    return _profiles[profileId];
  }

  @override
  Future<List<ChildProfile>> listProfiles() async {
    _check();
    final rows = _profiles.values.toList()
      ..sort((a, b) => a.nickname.compareTo(b.nickname));
    return rows;
  }

  @override
  Future<ChildProfile> updateProfile(ChildProfile profile) async {
    _check();
    final current = _profiles[profile.profileId];
    if (current == null) throw StateError('profile');
    final nickname = normalizeNickname(profile.nickname);
    if (nickname == null ||
        !validAvatar(profile.avatarId) ||
        !validAgeBand(profile.ageBand) ||
        !validLocale(profile.preferredLocale)) {
      throw ArgumentError('profile');
    }
    final next = profile.copyWith(
      nickname: nickname,
      revision: current.revision + 1,
    );
    _profiles[profile.profileId] = next;
    return next;
  }

  @override
  Future<void> setActiveProfileId(String profileId) async {
    _check();
    _active = profileId;
  }

  @override
  Future<String?> getActiveProfileId() async {
    _check();
    return _active;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    _check();
    _settings[key] = value;
  }

  @override
  Future<String?> getSetting(String key) async {
    _check();
    return _settings[key];
  }

  @override
  Future<void> saveDocument(StoredDocument document) async {
    _check();
    _documents['${document.contentId}@${document.contentVersion}'] = document;
  }

  @override
  Future<StoredDocument?> getDocument(
    String contentId,
    int contentVersion,
  ) async {
    _check();
    return _documents['$contentId@$contentVersion'];
  }

  @override
  Future<StoredDocument?> latestDocument(String contentId) async {
    _check();
    StoredDocument? latest;
    for (final document in _documents.values) {
      if (document.contentId != contentId) continue;
      if (latest == null || document.contentVersion > latest.contentVersion) {
        latest = document;
      }
    }
    return latest;
  }

  @override
  Future<List<StoredDocument>> listDocuments() async {
    _check();
    final rows = _documents.values.toList()
      ..sort((a, b) {
        final id = a.contentId.compareTo(b.contentId);
        if (id != 0) return id;
        return b.contentVersion.compareTo(a.contentVersion);
      });
    return rows;
  }

  @override
  Future<void> saveBlob(StoredBlob blob) async {
    _check();
    _blobs[blob.assetId] = blob;
  }

  @override
  Future<StoredBlob?> getBlob(String assetId) async {
    _check();
    return _blobs[assetId];
  }

  @override
  Future<void> deleteBlob(String assetId) async {
    _check();
    _blobs.remove(assetId);
  }

  @override
  Future<ApplyResult> applyEvent({
    required String profileId,
    required String categoryId,
    required LearningEvent event,
  }) async {
    _check();
    final owned = _events.values
        .where((item) => _profileOf(item) == profileId)
        .toList();
    final decision = decideProgress(
      profileId: profileId,
      categoryId: categoryId,
      current: _progress['$profileId|$categoryId'],
      existing: owned,
      event: event,
    );
    if (!decision.insertEvent) {
      return ApplyResult(inserted: false, summary: decision.summary);
    }
    _events[event.eventId] = event;
    _eventProfiles[event.eventId] = profileId;
    _progress['$profileId|$categoryId'] = decision.summary;
    _outbox.add(
      OutboxEntry(
        id: _outbox.length + 1,
        profileId: profileId,
        idempotencyKey: uuidV4(),
        body: eventBatchBody(event),
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    return ApplyResult(inserted: true, summary: decision.summary);
  }

  final Map<String, String> _eventProfiles = {};

  String? _profileOf(LearningEvent event) => _eventProfiles[event.eventId];

  @override
  Future<List<LearningEvent>> listEvents(String profileId) async {
    _check();
    return _events.values
        .where((event) => _eventProfiles[event.eventId] == profileId)
        .toList();
  }

  @override
  Future<List<ProgressSummary>> listProgress(String profileId) async {
    _check();
    return _progress.values.where((row) => row.profileId == profileId).toList();
  }

  @override
  Future<List<OutboxEntry>> listOutbox(String profileId) async {
    _check();
    return _outbox.where((row) => row.profileId == profileId).toList();
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}
