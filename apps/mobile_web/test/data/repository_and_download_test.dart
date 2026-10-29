import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/content/canonical_json.dart';
import 'package:little_genius/data/downloader.dart';
import 'package:little_genius/data/drift/drift_repository.dart';
import 'package:little_genius/data/memory/memory_repository.dart';
import 'package:little_genius/data/pack_downloader.dart';
import 'package:little_genius/data/records.dart';
import 'package:little_genius/domain/content_pack.dart';
import 'package:little_genius/domain/profile.dart';
import 'package:little_genius/domain/progress_rules.dart';

void main() {
  test('checksum failures and cancellation do not save a lesson', () async {
    final repository = MemoryLearningRepository();
    final image = Uint8List.fromList([1, 2, 3, 4]);
    final imageHash = sha256Hex(image);
    final document = _oneAssetLesson(imageHash);
    final lessonBytes = utf8.encode(canonicalJson(document));
    final lessonHash = sha256Hex(lessonBytes);
    final source = _MapSource({
      '/api/v1/content/animal.elephant.001': _pointer(lessonHash),
      '/api/v1/content/animal.elephant.001/versions/1': lessonBytes,
      '/api/v1/assets/img.elephant.001': utf8.encode(
        '{"assetId":"img.elephant.001","mediaType":"image","sha256":"$imageHash","byteSize":4,"url":"https://cdn.test/elephant","urlExpiresAt":"2099-01-01T00:00:00Z"}',
      ),
      'https://cdn.test/elephant': image,
    });
    final downloader = LessonDownloader(source: source, repository: repository);

    source.bodies['https://cdn.test/elephant'] = Uint8List.fromList([9, 9, 9]);
    final checksum = await downloader.download(
      contentId: 'animal.elephant.001',
      token: DownloadCancelToken(),
    );
    expect(checksum.status, DownloadStatus.checksumMismatch);
    expect(await repository.latestDocument('animal.elephant.001'), isNull);
    expect(await repository.getBlob('img.elephant.001'), isNull);

    source.bodies['https://cdn.test/elephant'] = image;
    final cancelled = await downloader.download(
      contentId: 'animal.elephant.001',
      token: DownloadCancelToken()..cancel(),
    );
    expect(cancelled.status, DownloadStatus.cancelled);
    expect(await repository.latestDocument('animal.elephant.001'), isNull);

    final saved = await downloader.download(
      contentId: 'animal.elephant.001',
      token: DownloadCancelToken(),
    );
    expect(saved.status, DownloadStatus.saved);
    expect(
      (await repository.latestDocument('animal.elephant.001'))!.payloadSha256,
      lessonHash,
    );
    expect((await repository.getBlob('img.elephant.001'))!.bytes, image);
    expect(
      await repository.storageUsedBytes(),
      lessonBytes.length + image.length,
    );
  });

  test('a bad pack checksum is rejected and the last manifest stays', () async {
    final repository = MemoryLearningRepository();
    await repository.setSetting(publishedPackSettingKey, 'last-good');
    final image = Uint8List.fromList([1, 2, 3, 4]);
    final imageHash = sha256Hex(image);
    final document = _oneAssetLesson(imageHash);
    final lessonBytes = utf8.encode(canonicalJson(document));
    final lessonHash = sha256Hex(lessonBytes);
    final pin = PackPin(
      position: 0,
      contentId: 'animal.elephant.001',
      contentVersion: 1,
      payloadSha256: lessonHash,
    );
    final source = _MapSource({
      '/api/v1/content/packs/$catalogPackId': utf8.encode(
        _packBody([pin], checksum: 'ab' * 32),
      ),
      '/api/v1/content/animal.elephant.001': _pointer(lessonHash),
      '/api/v1/content/animal.elephant.001/versions/1': lessonBytes,
      '/api/v1/assets/img.elephant.001': utf8.encode(
        '{"assetId":"img.elephant.001","mediaType":"image","sha256":"$imageHash","byteSize":4,"url":"https://cdn.test/elephant","urlExpiresAt":"2099-01-01T00:00:00Z"}',
      ),
      'https://cdn.test/elephant': image,
    });
    final downloader = PackDownloader(source: source, repository: repository);
    final rejected = await downloader.download(
      packId: catalogPackId,
      token: DownloadCancelToken(),
    );
    expect(rejected.status, DownloadStatus.checksumMismatch);
    expect(await repository.getSetting(publishedPackSettingKey), 'last-good');
    expect(await repository.latestDocument('animal.elephant.001'), isNull);

    source.bodies['/api/v1/content/packs/$catalogPackId'] = utf8.encode(
      _packBody([pin]),
    );
    final saved = await downloader.download(
      packId: catalogPackId,
      token: DownloadCancelToken(),
    );
    expect(saved.status, DownloadStatus.saved);
    final installed = parseContentPack(
      jsonDecode((await repository.getSetting(publishedPackSettingKey))!),
    );
    expect(installed, isNotNull);
    expect(installed!.packVersion, 1);
    expect(
      (await repository.latestDocument('animal.elephant.001'))!.payloadSha256,
      lessonHash,
    );
  });

  test(
    'progress and the outbox survive closing and reopening sqlite',
    () async {
      final directory = await Directory.systemTemp.createTemp('little-genius');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/lesson.sqlite');
      final first = DriftLearningRepository.openFile(file);
      final profile = await first.createProfile(
        const ProfileDraft(
          nickname: 'Asha',
          avatarId: 'leaf',
          ageBand: '2-3',
          preferredLocale: 'ta',
          bilingualMode: true,
        ),
      );
      await first.setActiveProfileId(profile.profileId);
      expect(
        (await first.applyEvent(
          profileId: profile.profileId,
          categoryId: 'animals',
          event: _event('started-1', 'started'),
        )).inserted,
        isTrue,
      );
      expect(
        (await first.applyEvent(
          profileId: profile.profileId,
          categoryId: 'animals',
          event: _event('completed-1', 'completed'),
        )).inserted,
        isTrue,
      );
      expect(
        (await first.applyEvent(
          profileId: profile.profileId,
          categoryId: 'animals',
          event: _event('completed-2', 'completed'),
        )).inserted,
        isFalse,
      );
      expect(await first.listOutbox(profile.profileId), hasLength(2));
      await first.setSetting('session_limit_minutes', '10');
      await first.close();

      final reopened = DriftLearningRepository.openFile(file);
      final progress = await reopened.listProgress(profile.profileId);
      expect(progress.single.startedCount, 1);
      expect(progress.single.completedCount, 1);
      final outbox = await reopened.listOutbox(profile.profileId);
      expect(outbox, hasLength(2));
      expect(outbox.every((row) => !row.body.contains('http')), isTrue);
      expect(
        (await reopened.getProfile(profile.profileId))!.preferredLocale,
        'ta',
      );
      expect(await reopened.getActiveProfileId(), profile.profileId);
      expect(await reopened.getSetting('session_limit_minutes'), '10');
      await reopened.saveDocument(
        const StoredDocument(
          contentId: 'color.red.001',
          contentVersion: 1,
          payload: 'hi',
          payloadSha256: 'aa',
        ),
      );
      await reopened.saveBlob(
        StoredBlob(
          assetId: 'img.x',
          sha256: 'bb',
          mediaType: 'image',
          bytes: Uint8List.fromList([1, 2]),
        ),
      );
      expect(await reopened.storageUsedBytes(), 4);
      await reopened.close();
      final stored = DriftLearningRepository.openFile(file);
      expect(await stored.storageUsedBytes(), 4);
      await stored.close();
    },
  );

  test('the web store source does not reference sqlite', () {
    final source = File('lib/data/indexeddb/indexeddb_repository.dart')
        .readAsStringSync();
    expect(source.contains('sqlite'), isFalse);
    expect(source.contains('drift'), isFalse);
    final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();
    expect(pubspec.contains('webview'), isFalse);
    expect(pubspec.contains('flutter_html'), isFalse);
  });
}

Map<String, dynamic> _oneAssetLesson(String imageHash) {
  final document = jsonDecode(
    File('../../infrastructure/fixtures/animal.elephant.001.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  document['assets'] = [
    {'assetId': 'img.elephant.001', 'mediaType': 'image', 'sha256': imageHash},
  ];
  final localizations = document['localizations'] as Map;
  for (final copy in localizations.values) {
    (copy as Map).remove('audio');
  }
  return document;
}

String _packBody(List<PackPin> items, {String? checksum}) {
  final sum = checksum ?? sha256Hex(utf8.encode(packMaterial(items)));
  return jsonEncode({
    'packId': catalogPackId,
    'packVersion': 1,
    'checksumSha256': sum,
    'totalBytes': 4,
    'minAppVersion': '0.1.0',
    'items': [
      for (final item in items)
        {
          'position': item.position,
          'contentId': item.contentId,
          'contentVersion': item.contentVersion,
          'payloadSha256': item.payloadSha256,
        },
    ],
  });
}

List<int> _pointer(String hash) {
  return utf8.encode(
    '{"contentId":"animal.elephant.001","contentVersion":1,"schemaVersion":"1.0","payloadSha256":"$hash","minAppVersion":"0.1.0"}',
  );
}

LearningEvent _event(String id, String type) {
  return LearningEvent(
    eventId: id,
    contentId: 'animal.elephant.001',
    contentVersion: 1,
    eventType: type,
    occurredAt: DateTime.utc(2026, 10, 29, 12),
    durationBucket: type == 'completed' ? 'lt_1m' : null,
  );
}

class _MapSource implements ByteSource {
  _MapSource(this.bodies);

  final Map<String, List<int>> bodies;

  @override
  Future<List<int>> get(Uri uri, DownloadCancelToken token) async {
    if (token.cancelled) throw const DownloadCancelled();
    final body = bodies[uri.toString()] ?? bodies[uri.path];
    if (body == null) throw StateError('missing $uri');
    return body;
  }
}
