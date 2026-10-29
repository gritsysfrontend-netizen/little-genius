import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/content/canonical_json.dart';
import 'package:little_genius/data/indexeddb/indexeddb_repository.dart';
import 'package:little_genius/data/records.dart';
import 'package:little_genius/domain/profile.dart';
import 'package:little_genius/domain/progress_rules.dart';

void main() {
  test('profile, progress, and blob bytes survive a new connection', () async {
    final name = 'little-genius-test-${DateTime.now().microsecondsSinceEpoch}';
    final first = await IndexedDbLearningRepository.open(name: name);
    final profile = await first.createProfile(
      const ProfileDraft(
        nickname: 'Asha',
        avatarId: 'moon',
        ageBand: '1-2',
        preferredLocale: 'hi',
        bilingualMode: true,
      ),
    );
    await first.setActiveProfileId(profile.profileId);
    final bytes = Uint8List.fromList([9, 8, 7, 6]);
    await first.saveBlob(
      StoredBlob(
        assetId: 'img.elephant.001',
        sha256: sha256Hex(bytes),
        mediaType: 'image',
        bytes: bytes,
      ),
    );
    await first.applyEvent(
      profileId: profile.profileId,
      categoryId: 'animals',
      event: LearningEvent(
        eventId: 'started-1',
        contentId: 'animal.elephant.001',
        contentVersion: 1,
        eventType: 'started',
        occurredAt: DateTime.utc(2026, 10, 29, 12),
      ),
    );
    await first.applyEvent(
      profileId: profile.profileId,
      categoryId: 'animals',
      event: LearningEvent(
        eventId: 'completed-1',
        contentId: 'animal.elephant.001',
        contentVersion: 1,
        eventType: 'completed',
        occurredAt: DateTime.utc(2026, 10, 29, 12, 1),
        durationBucket: 'lt_1m',
      ),
    );
    await first.setSetting('session_limit_minutes', '15');
    await first.close();

    final second = await IndexedDbLearningRepository.open(name: name);
    addTearDown(() async {
      await second.close();
      await IndexedDbLearningRepository.deleteDatabase(name);
    });
    expect((await second.getProfile(profile.profileId))!.preferredLocale, 'hi');
    expect(await second.getActiveProfileId(), profile.profileId);
    final progress = await second.listProgress(profile.profileId);
    expect(progress.single.completedCount, 1);
    expect(await second.listOutbox(profile.profileId), hasLength(2));
    expect((await second.getBlob('img.elephant.001'))!.bytes, bytes);
    expect(await second.getSetting('session_limit_minutes'), '15');
  });
}
