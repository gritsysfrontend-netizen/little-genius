import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../domain/ids.dart';
import '../../domain/profile.dart';
import '../../domain/progress_rules.dart';
import '../learning_repository.dart';
import '../profile_factory.dart';
import '../records.dart';
import 'app_database.dart';

class DriftLearningRepository implements LearningRepository {
  DriftLearningRepository(this._db);

  final AppDatabase _db;

  static DriftLearningRepository openFile(File file) {
    return DriftLearningRepository(AppDatabase(NativeDatabase(file)));
  }

  @override
  Future<ChildProfile> createProfile(ProfileDraft draft) async {
    final profile = profileFromDraft(draft);
    await _db
        .into(_db.profileRows)
        .insert(
          ProfileRowsCompanion.insert(
            profileId: profile.profileId,
            nickname: profile.nickname,
            avatarId: profile.avatarId,
            ageBand: profile.ageBand,
            preferredLocale: profile.preferredLocale,
            bilingualMode: profile.bilingualMode,
            revision: profile.revision,
          ),
        );
    return profile;
  }

  @override
  Future<ChildProfile?> getProfile(String profileId) async {
    final row = await (_db.select(
      _db.profileRows,
    )..where((table) => table.profileId.equals(profileId))).getSingleOrNull();
    return row == null ? null : _profile(row);
  }

  @override
  Future<List<ChildProfile>> listProfiles() async {
    final rows = await (_db.select(
      _db.profileRows,
    )..orderBy([(table) => OrderingTerm.asc(table.nickname)])).get();
    return rows.map(_profile).toList();
  }

  @override
  Future<ChildProfile> updateProfile(ChildProfile profile) async {
    final current = await getProfile(profile.profileId);
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
    await (_db.update(
      _db.profileRows,
    )..where((table) => table.profileId.equals(profile.profileId))).write(
      ProfileRowsCompanion(
        nickname: Value(next.nickname),
        avatarId: Value(next.avatarId),
        ageBand: Value(next.ageBand),
        preferredLocale: Value(next.preferredLocale),
        bilingualMode: Value(next.bilingualMode),
        revision: Value(next.revision),
      ),
    );
    return next;
  }

  @override
  Future<void> setActiveProfileId(String profileId) async {
    await _db
        .into(_db.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(
            key: 'active_profile_id',
            value: profileId,
          ),
        );
  }

  @override
  Future<String?> getActiveProfileId() async {
    final row =
        await (_db.select(_db.settingRows)
              ..where((table) => table.key.equals('active_profile_id')))
            .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _db
        .into(_db.settingRows)
        .insertOnConflictUpdate(
          SettingRowsCompanion.insert(key: key, value: value),
        );
  }

  @override
  Future<String?> getSetting(String key) async {
    final row = await (_db.select(
      _db.settingRows,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> saveDocument(StoredDocument document) async {
    await _db
        .into(_db.documentRows)
        .insertOnConflictUpdate(
          DocumentRowsCompanion.insert(
            contentId: document.contentId,
            contentVersion: document.contentVersion,
            payload: document.payload,
            payloadSha256: document.payloadSha256,
          ),
        );
  }

  @override
  Future<StoredDocument?> getDocument(
    String contentId,
    int contentVersion,
  ) async {
    final row =
        await (_db.select(_db.documentRows)..where(
              (table) =>
                  table.contentId.equals(contentId) &
                  table.contentVersion.equals(contentVersion),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return StoredDocument(
      contentId: row.contentId,
      contentVersion: row.contentVersion,
      payload: row.payload,
      payloadSha256: row.payloadSha256,
    );
  }

  @override
  Future<StoredDocument?> latestDocument(String contentId) async {
    final row =
        await (_db.select(_db.documentRows)
              ..where((table) => table.contentId.equals(contentId))
              ..orderBy([(table) => OrderingTerm.desc(table.contentVersion)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return StoredDocument(
      contentId: row.contentId,
      contentVersion: row.contentVersion,
      payload: row.payload,
      payloadSha256: row.payloadSha256,
    );
  }

  @override
  Future<List<StoredDocument>> listDocuments() async {
    final rows =
        await (_db.select(_db.documentRows)..orderBy([
              (table) => OrderingTerm.asc(table.contentId),
              (table) => OrderingTerm.desc(table.contentVersion),
            ]))
            .get();
    return rows
        .map(
          (row) => StoredDocument(
            contentId: row.contentId,
            contentVersion: row.contentVersion,
            payload: row.payload,
            payloadSha256: row.payloadSha256,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveBlob(StoredBlob blob) async {
    await _db
        .into(_db.blobRows)
        .insertOnConflictUpdate(
          BlobRowsCompanion.insert(
            assetId: blob.assetId,
            sha256: blob.sha256,
            mediaType: blob.mediaType,
            bytes: blob.bytes,
          ),
        );
  }

  @override
  Future<StoredBlob?> getBlob(String assetId) async {
    final row = await (_db.select(
      _db.blobRows,
    )..where((table) => table.assetId.equals(assetId))).getSingleOrNull();
    if (row == null) return null;
    return StoredBlob(
      assetId: row.assetId,
      sha256: row.sha256,
      mediaType: row.mediaType,
      bytes: row.bytes,
    );
  }

  @override
  Future<void> deleteBlob(String assetId) async {
    await (_db.delete(
      _db.blobRows,
    )..where((table) => table.assetId.equals(assetId))).go();
  }

  @override
  Future<ApplyResult> applyEvent({
    required String profileId,
    required String categoryId,
    required LearningEvent event,
  }) {
    return _db.transaction(() async {
      final rows = await (_db.select(
        _db.eventRows,
      )..where((table) => table.profileId.equals(profileId))).get();
      final existing = rows.map(_event).toList();
      final current =
          await (_db.select(_db.progressRows)..where(
                (table) =>
                    table.profileId.equals(profileId) &
                    table.categoryId.equals(categoryId),
              ))
              .getSingleOrNull();
      final decision = decideProgress(
        profileId: profileId,
        categoryId: categoryId,
        current: current == null
            ? null
            : ProgressSummary(
                profileId: current.profileId,
                categoryId: current.categoryId,
                startedCount: current.startedCount,
                completedCount: current.completedCount,
                lastActivityAt: current.lastActivityAt == null
                    ? null
                    : DateTime.parse(current.lastActivityAt!),
              ),
        existing: existing,
        event: event,
      );
      if (!decision.insertEvent) {
        return ApplyResult(inserted: false, summary: decision.summary);
      }
      await _db
          .into(_db.eventRows)
          .insert(
            EventRowsCompanion.insert(
              eventId: event.eventId,
              profileId: profileId,
              contentId: event.contentId,
              contentVersion: event.contentVersion,
              eventType: event.eventType,
              durationBucket: Value(event.durationBucket),
              occurredAt: event.occurredAt.toUtc().toIso8601String(),
            ),
          );
      await _db
          .into(_db.progressRows)
          .insertOnConflictUpdate(
            ProgressRowsCompanion.insert(
              profileId: profileId,
              categoryId: categoryId,
              startedCount: decision.summary.startedCount,
              completedCount: decision.summary.completedCount,
              lastActivityAt: Value(
                decision.summary.lastActivityAt?.toUtc().toIso8601String(),
              ),
            ),
          );
      await _db
          .into(_db.outboxRows)
          .insert(
            OutboxRowsCompanion.insert(
              profileId: profileId,
              idempotencyKey: uuidV4(),
              body: eventBatchBody(event),
              createdAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
      return ApplyResult(inserted: true, summary: decision.summary);
    });
  }

  @override
  Future<List<LearningEvent>> listEvents(String profileId) async {
    final rows = await (_db.select(
      _db.eventRows,
    )..where((table) => table.profileId.equals(profileId))).get();
    return rows.map(_event).toList();
  }

  @override
  Future<List<ProgressSummary>> listProgress(String profileId) async {
    final rows = await (_db.select(
      _db.progressRows,
    )..where((table) => table.profileId.equals(profileId))).get();
    return rows
        .map(
          (row) => ProgressSummary(
            profileId: row.profileId,
            categoryId: row.categoryId,
            startedCount: row.startedCount,
            completedCount: row.completedCount,
            lastActivityAt: row.lastActivityAt == null
                ? null
                : DateTime.parse(row.lastActivityAt!),
          ),
        )
        .toList();
  }

  @override
  Future<List<OutboxEntry>> listOutbox(String profileId) async {
    final rows = await (_db.select(
      _db.outboxRows,
    )..where((table) => table.profileId.equals(profileId))).get();
    return rows
        .map(
          (row) => OutboxEntry(
            id: row.id,
            profileId: row.profileId,
            idempotencyKey: row.idempotencyKey,
            body: row.body,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> close() => _db.close();

  ChildProfile _profile(ProfileRow row) {
    return ChildProfile(
      profileId: row.profileId,
      nickname: row.nickname,
      avatarId: row.avatarId,
      ageBand: row.ageBand,
      preferredLocale: row.preferredLocale,
      bilingualMode: row.bilingualMode,
      revision: row.revision,
    );
  }

  LearningEvent _event(EventRow row) {
    return LearningEvent(
      eventId: row.eventId,
      contentId: row.contentId,
      contentVersion: row.contentVersion,
      eventType: row.eventType,
      occurredAt: DateTime.parse(row.occurredAt),
      durationBucket: row.durationBucket,
    );
  }
}
