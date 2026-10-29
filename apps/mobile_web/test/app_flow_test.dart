import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/app.dart';
import 'package:little_genius/content/canonical_json.dart';
import 'package:little_genius/data/downloader.dart';
import 'package:little_genius/data/memory/memory_repository.dart';
import 'package:little_genius/data/records.dart';
import 'package:little_genius/domain/profile.dart';
import 'package:little_genius/routing/providers.dart';

void main() {
  testWidgets('onboarding creates a Tamil profile without a network call', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = MemoryLearningRepository();
    await tester.pumpWidget(_app(repository, _OfflineSource()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-ta')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('தொடருங்கள்'));
    await tester.pumpAndSettle();
    expect(find.text('இது இந்தச் சாதனத்திலேயே இருக்கும்'), findsOneWidget);
    expect(
      find.text(
        'இந்தப் பதிப்பில் கணக்கு இல்லை. எதுவும் பதிவேற்றப்படாது. எதிர்காலக் கணக்கு தனித் தேர்வாக இருக்கும், அது இப்போது இயக்கப்படவில்லை.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('create-account')), findsNothing);
    await tester.tap(find.text('தொடருங்கள்'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nickname-field')), 'Asha');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(find.text('வணக்கம், Asha'), findsOneWidget);
    final profiles = await repository.listProfiles();
    expect(profiles.single.preferredLocale, 'ta');
    expect(profiles.single.nickname, 'Asha');
    expect(await repository.listOutbox(profiles.single.profileId), isEmpty);
  });

  testWidgets(
    'the parent gate blocks grown-up pages until the answer is right',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = MemoryLearningRepository();
      final profile = await repository.createProfile(
        const ProfileDraft(
          nickname: 'Asha',
          avatarId: 'star',
          ageBand: '3-4',
          preferredLocale: 'en',
          bilingualMode: false,
        ),
      );
      await repository.setActiveProfileId(profile.profileId);
      await tester.pumpWidget(_app(repository, _OfflineSource()));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Asha'), findsOneWidget);
      await tester.tap(find.byKey(const Key('grown-ups')));
      await tester.pumpAndSettle();
      expect(find.text('What is 3 + 4?'), findsWidgets);
      expect(find.text('Accounts are not in this version.'), findsNothing);
      await tester.enterText(find.byKey(const Key('gate-answer')), '6');
      await tester.tap(find.byKey(const Key('gate-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Try again.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('gate-answer')), '7');
      await tester.tap(find.byKey(const Key('gate-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Accounts are not in this version.'), findsOneWidget);
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-ta')));
      await tester.pumpAndSettle();
      expect(find.text('மொழியைத் தேர்ந்தெடுங்கள்'), findsOneWidget);
      await tester.tap(find.byKey(const Key('home-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('grown-ups')));
      await tester.pumpAndSettle();
      expect(find.text('3 + 4 எவ்வளவு?'), findsWidgets);
      expect(find.text('Accounts are not in this version.'), findsNothing);
    },
  );

  testWidgets(
    'a downloaded lesson plays offline and completion is stored once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = MemoryLearningRepository();
      final profile = await repository.createProfile(
        const ProfileDraft(
          nickname: 'Asha',
          avatarId: 'bird',
          ageBand: '2-3',
          preferredLocale: 'en',
          bilingualMode: true,
        ),
      );
      await repository.setActiveProfileId(profile.profileId);
      await _saveFixture(repository);
      await tester.pumpWidget(_app(repository, _OfflineSource()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category-pairs')), findsOneWidget);
      expect(find.byKey(const Key('category-colors')), findsNothing);
      await tester.tap(find.byKey(const Key('animals-button')));
      await tester.pumpAndSettle();
      expect(find.text('Elephant'), findsOneWidget);
      expect(find.text('हाथी'), findsNothing);
      await tester.tap(find.byKey(const Key('play-animal.elephant.001')));
      await tester.pumpAndSettle();
      expect(find.text('Tap the elephant'), findsOneWidget);
      expect(find.text('हाथी'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tap-target')));
      await tester.pumpAndSettle();
      expect(find.text('Great exploring!'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tap-target')));
      await tester.pumpAndSettle();
      final progress = await repository.listProgress(profile.profileId);
      expect(progress.single.startedCount, 1);
      expect(progress.single.completedCount, 1);
      expect(await repository.listOutbox(profile.profileId), hasLength(2));
    },
  );
}

Widget _app(MemoryLearningRepository repository, ByteSource source) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repository),
      byteSourceProvider.overrideWithValue(source),
    ],
    child: const LittleGeniusApp(),
  );
}

class _OfflineSource implements ByteSource {
  @override
  Future<List<int>> get(Uri uri, DownloadCancelToken token) async {
    throw StateError('offline');
  }
}

Future<void> _saveFixture(MemoryLearningRepository repository) async {
  final raw = File('../../infrastructure/fixtures/animal.elephant.001.json')
      .readAsStringSync();
  final canonical = canonicalJson(jsonDecode(raw));
  final recorded = jsonDecode(
    File('../../infrastructure/fixtures/checksums.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  await repository.saveDocument(
    StoredDocument(
      contentId: 'animal.elephant.001',
      contentVersion: 1,
      payload: canonical,
      payloadSha256: recorded['payloadSha256']! as String,
    ),
  );
  final assets = recorded['assets']! as Map<String, dynamic>;
  for (final entry in assets.entries) {
    final info = entry.value as Map<String, dynamic>;
    final bytes = Uint8List.fromList(
      File('../../infrastructure/fixtures/${info['file']}').readAsBytesSync(),
    );
    await repository.saveBlob(
      StoredBlob(
        assetId: entry.key,
        sha256: info['sha256']! as String,
        mediaType: entry.key.startsWith('img.') ? 'image' : 'audio',
        bytes: bytes,
      ),
    );
  }
}
