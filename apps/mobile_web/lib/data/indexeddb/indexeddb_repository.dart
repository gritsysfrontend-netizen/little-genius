import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import '../../domain/ids.dart';
import '../../domain/profile.dart';
import '../../domain/progress_rules.dart';
import '../learning_repository.dart';
import '../profile_factory.dart';
import '../records.dart';

const _stores = [
  'profiles',
  'events',
  'progress',
  'outbox',
  'documents',
  'blobs',
  'settings',
];

class IndexedDbLearningRepository implements LearningRepository {
  IndexedDbLearningRepository(this._db);

  final IDBDatabase _db;

  static Future<IndexedDbLearningRepository> open({
    String name = 'little_genius',
  }) async {
    final request = window.indexedDB.open(name, 1);
    request.onupgradeneeded = ((Event _) {
      final database = request.result as IDBDatabase;
      for (final store in _stores) {
        if (!database.objectStoreNames.contains(store)) {
          database.createObjectStore(store);
        }
      }
    }).toJS;
    final result = await _wait(request);
    return IndexedDbLearningRepository(result as IDBDatabase);
  }

  static Future<void> deleteDatabase(String name) async {
    await _wait(window.indexedDB.deleteDatabase(name));
  }

  @override
  Future<ChildProfile> createProfile(ProfileDraft draft) async {
    final profile = profileFromDraft(draft);
    await _put(
      'profiles',
      profile.profileId,
      jsonEncode(_profileJson(profile)),
    );
    return profile;
  }

  @override
  Future<ChildProfile?> getProfile(String profileId) async {
    final raw = await _get('profiles', profileId);
    return raw == null ? null : _profile(raw);
  }

  @override
  Future<List<ChildProfile>> listProfiles() async {
    final rows = await _all('profiles');
    final profiles = rows.map(_profile).toList()
      ..sort((a, b) => a.nickname.compareTo(b.nickname));
    return profiles;
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
    await _put('profiles', next.profileId, jsonEncode(_profileJson(next)));
    return next;
  }

  @override
  Future<void> setActiveProfileId(String profileId) =>
      _put('settings', 'active_profile_id', profileId);

  @override
  Future<String?> getActiveProfileId() => _get('settings', 'active_profile_id');

  @override
  Future<void> setSetting(String key, String value) =>
      _put('settings', key, value);

  @override
  Future<String?> getSetting(String key) => _get('settings', key);

  @override
  Future<void> saveDocument(StoredDocument document) {
    return _put(
      'documents',
      _documentKey(document.contentId, document.contentVersion),
      jsonEncode(_documentJson(document)),
    );
  }

  @override
  Future<StoredDocument?> getDocument(
    String contentId,
    int contentVersion,
  ) async {
    final raw = await _get(
      'documents',
      _documentKey(contentId, contentVersion),
    );
    return raw == null ? null : _document(raw);
  }

  @override
  Future<StoredDocument?> latestDocument(String contentId) async {
    StoredDocument? latest;
    for (final raw in await _all('documents')) {
      final document = _document(raw);
      if (document.contentId != contentId) continue;
      if (latest == null || document.contentVersion > latest.contentVersion) {
        latest = document;
      }
    }
    return latest;
  }

  @override
  Future<List<StoredDocument>> listDocuments() async {
    final rows = (await _all('documents')).map(_document).toList()
      ..sort((a, b) {
        final id = a.contentId.compareTo(b.contentId);
        if (id != 0) return id;
        return b.contentVersion.compareTo(a.contentVersion);
      });
    return rows;
  }

  @override
  Future<void> saveBlob(StoredBlob blob) {
    return _put(
      'blobs',
      blob.assetId,
      jsonEncode({
        'assetId': blob.assetId,
        'sha256': blob.sha256,
        'mediaType': blob.mediaType,
        'base64': base64Encode(blob.bytes),
      }),
    );
  }

  @override
  Future<StoredBlob?> getBlob(String assetId) async {
    final raw = await _get('blobs', assetId);
    if (raw == null) return null;
    final json = _map(jsonDecode(raw));
    return StoredBlob(
      assetId: json['assetId']! as String,
      sha256: json['sha256']! as String,
      mediaType: json['mediaType']! as String,
      bytes: Uint8List.fromList(base64Decode(json['base64']! as String)),
    );
  }

  @override
  Future<void> deleteBlob(String assetId) => _delete('blobs', assetId);

  @override
  Future<int> storageUsedBytes() async {
    var total = 0;
    for (final raw in await _all('documents')) {
      total += utf8.encode(_document(raw).payload).length;
    }
    for (final raw in await _all('blobs')) {
      final json = _map(jsonDecode(raw));
      final encoded = json['base64'];
      if (encoded is! String) continue;
      total += base64Decode(encoded).length;
    }
    return total;
  }

  @override
  Future<ApplyResult> applyEvent({
    required String profileId,
    required String categoryId,
    required LearningEvent event,
  }) async {
    final existing = <LearningEvent>[];
    for (final raw in await _all('events')) {
      final stored = _storedEvent(raw);
      if (stored.profileId == profileId) existing.add(stored.event);
    }
    final currentRaw = await _get('progress', '$profileId|$categoryId');
    final decision = decideProgress(
      profileId: profileId,
      categoryId: categoryId,
      current: currentRaw == null ? null : _summary(currentRaw),
      existing: existing,
      event: event,
    );
    if (!decision.insertEvent) {
      return ApplyResult(inserted: false, summary: decision.summary);
    }
    await _put(
      'events',
      event.eventId,
      jsonEncode({'profileId': profileId, 'event': event.toJson()}),
    );
    await _put(
      'progress',
      '$profileId|$categoryId',
      jsonEncode({
        'profileId': profileId,
        'categoryId': categoryId,
        'startedCount': decision.summary.startedCount,
        'completedCount': decision.summary.completedCount,
        'lastActivityAt': decision.summary.lastActivityAt
            ?.toUtc()
            .toIso8601String(),
      }),
    );
    final outbox = await _all('outbox');
    var maxId = 0;
    for (final raw in outbox) {
      final id = _map(jsonDecode(raw))['id'];
      if (id is int && id > maxId) maxId = id;
    }
    final id = maxId + 1;
    await _put(
      'outbox',
      '$id',
      jsonEncode({
        'id': id,
        'profileId': profileId,
        'idempotencyKey': uuidV4(),
        'body': eventBatchBody(event),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return ApplyResult(inserted: true, summary: decision.summary);
  }

  @override
  Future<List<LearningEvent>> listEvents(String profileId) async {
    final events = <LearningEvent>[];
    for (final raw in await _all('events')) {
      final stored = _storedEvent(raw);
      if (stored.profileId == profileId) events.add(stored.event);
    }
    return events;
  }

  @override
  Future<List<ProgressSummary>> listProgress(String profileId) async {
    return [
      for (final raw in await _all('progress'))
        if (_summary(raw).profileId == profileId) _summary(raw),
    ];
  }

  @override
  Future<List<OutboxEntry>> listOutbox(String profileId) async {
    final rows = <OutboxEntry>[];
    for (final raw in await _all('outbox')) {
      final json = _map(jsonDecode(raw));
      if (json['profileId'] != profileId) continue;
      rows.add(
        OutboxEntry(
          id: json['id']! as int,
          profileId: profileId,
          idempotencyKey: json['idempotencyKey']! as String,
          body: json['body']! as String,
          createdAt: json['createdAt']! as String,
        ),
      );
    }
    return rows;
  }

  @override
  Future<void> close() async {
    _db.close();
  }

  Future<void> _put(String store, String key, String value) {
    final objectStore = _db
        .transaction(store.toJS, 'readwrite')
        .objectStore(store);
    return _wait(objectStore.put(value.toJS, key.toJS));
  }

  Future<String?> _get(String store, String key) async {
    final objectStore = _db
        .transaction(store.toJS, 'readonly')
        .objectStore(store);
    final result = await _wait(objectStore.get(key.toJS));
    if (result == null || result.isUndefined) return null;
    return (result as JSString).toDart;
  }

  Future<void> _delete(String store, String key) {
    final objectStore = _db
        .transaction(store.toJS, 'readwrite')
        .objectStore(store);
    return _wait(objectStore.delete(key.toJS));
  }

  Future<List<String>> _all(String store) async {
    final objectStore = _db
        .transaction(store.toJS, 'readonly')
        .objectStore(store);
    final result = await _wait(objectStore.getAll());
    if (result == null || result.isUndefined) return const [];
    final values = <String>[];
    for (final item in (result as JSArray<JSAny?>).toDart) {
      if (item == null || item.isUndefined) continue;
      values.add((item as JSString).toDart);
    }
    return values;
  }
}

Future<JSAny?> _wait(IDBRequest request) {
  final completer = Completer<JSAny?>();
  request.onsuccess = ((Event _) {
    if (!completer.isCompleted) completer.complete(request.result);
  }).toJS;
  request.onerror = ((Event event) {
    event.preventDefault();
    if (!completer.isCompleted) {
      completer.completeError(request.error ?? StateError('idb'));
    }
  }).toJS;
  return completer.future;
}

String _documentKey(String contentId, int contentVersion) =>
    '$contentId@$contentVersion';

Map<String, Object?> _map(Object? value) {
  final source = value! as Map;
  return source.map((key, item) => MapEntry(key.toString(), item as Object?));
}

Map<String, Object?> _profileJson(ChildProfile profile) {
  return {
    'profileId': profile.profileId,
    'nickname': profile.nickname,
    'avatarId': profile.avatarId,
    'ageBand': profile.ageBand,
    'preferredLocale': profile.preferredLocale,
    'bilingualMode': profile.bilingualMode,
    'revision': profile.revision,
  };
}

ChildProfile _profile(String raw) {
  final json = _map(jsonDecode(raw));
  return ChildProfile(
    profileId: json['profileId']! as String,
    nickname: json['nickname']! as String,
    avatarId: json['avatarId']! as String,
    ageBand: json['ageBand']! as String,
    preferredLocale: json['preferredLocale']! as String,
    bilingualMode: json['bilingualMode']! as bool,
    revision: json['revision']! as int,
  );
}

Map<String, Object?> _documentJson(StoredDocument document) {
  return {
    'contentId': document.contentId,
    'contentVersion': document.contentVersion,
    'payload': document.payload,
    'payloadSha256': document.payloadSha256,
  };
}

StoredDocument _document(String raw) {
  final json = _map(jsonDecode(raw));
  return StoredDocument(
    contentId: json['contentId']! as String,
    contentVersion: json['contentVersion']! as int,
    payload: json['payload']! as String,
    payloadSha256: json['payloadSha256']! as String,
  );
}

({String profileId, LearningEvent event}) _storedEvent(String raw) {
  final json = _map(jsonDecode(raw));
  return (
    profileId: json['profileId']! as String,
    event: LearningEvent.fromJson(_map(json['event'])),
  );
}

ProgressSummary _summary(String raw) {
  final json = _map(jsonDecode(raw));
  final at = json['lastActivityAt'];
  return ProgressSummary(
    profileId: json['profileId']! as String,
    categoryId: json['categoryId']! as String,
    startedCount: json['startedCount']! as int,
    completedCount: json['completedCount']! as int,
    lastActivityAt: at is String ? DateTime.parse(at) : null,
  );
}
