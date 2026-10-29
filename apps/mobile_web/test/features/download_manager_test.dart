import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/content/canonical_json.dart';
import 'package:little_genius/data/downloader.dart';
import 'package:little_genius/data/memory/memory_repository.dart';
import 'package:little_genius/data/records.dart';
import 'package:little_genius/domain/content_pack.dart';
import 'package:little_genius/features/parent/download_manager.dart';
import 'package:little_genius/features/parent/parent_screens.dart';
import 'package:little_genius/l10n/app_localizations.dart';
import 'package:little_genius/routing/providers.dart';
import 'package:little_genius/theme/app_theme.dart';

void main() {
  test('a rejected pack leaves the installed manifest in place', () {
    const installed = '''
{"packId":"pack.catalog.001","packVersion":2,"checksumSha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","totalBytes":1,"minAppVersion":"0.1.0","items":[{"position":0,"contentId":"color.red.001","contentVersion":1,"payloadSha256":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}]}
''';
    final snapshot = describeDownloads(
      storageBytes: 12,
      installedJson: _withChecksum(installed),
      fetchedJson:
          '{"packId":"pack.catalog.001","checksumSha256":"${'c' * 64}"}',
      fetchFailed: false,
      documents: const [],
    );
    expect(snapshot.checksumRejected, isTrue);
    expect(snapshot.installedPackVersion, 2);
    expect(snapshot.offline, isFalse);
    expect(snapshot.lessons.single.contentId, 'color.red.001');
    expect(snapshot.lessons.single.downloaded, isFalse);
  });

  testWidgets('downloads show storage, missing lessons, cancel, and retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = MemoryLearningRepository();
    await repository.saveDocument(
      const StoredDocument(
        contentId: 'animal.elephant.001',
        contentVersion: 1,
        payload: 'hello',
        payloadSha256: 'abc',
      ),
    );
    final source = _FailSource();
    await tester.pumpWidget(_app(repository, source));
    await tester.pumpAndSettle();
    expect(find.text('Storage used: 5 bytes'), findsOneWidget);
    expect(
      find.text('You are offline. Saved activities can still be played.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('downloaded-animal.elephant.001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('not-downloaded-color.red.001')),
      findsOneWidget,
    );
    expect(find.text('Not downloaded'), findsWidgets);

    await tester.tap(find.byKey(const Key('download-pack')));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);

    final holding = _HoldSource();
    await tester.pumpWidget(_app(repository, holding));
    await tester.pumpAndSettle();
    holding.hold = true;
    await tester.tap(find.byKey(const Key('download-pack')));
    await tester.pump();
    expect(find.byKey(const Key('cancel-pack')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-pack')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.byKey(const Key('cancel-pack')), findsNothing);
  });
}

String _withChecksum(String raw) {
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final pack = ContentPackDocument(
    packId: decoded['packId'] as String,
    packVersion: decoded['packVersion'] as int,
    checksumSha256: '',
    totalBytes: decoded['totalBytes'] as int,
    minAppVersion: decoded['minAppVersion'] as String,
    items: [
      for (final item in decoded['items'] as List)
        PackPin(
          position: (item as Map)['position'] as int,
          contentId: item['contentId'] as String,
          contentVersion: item['contentVersion'] as int,
          payloadSha256: item['payloadSha256'] as String,
        ),
    ],
  );
  decoded['checksumSha256'] = sha256Hex(utf8.encode(packMaterial(pack.items)));
  return jsonEncode(decoded);
}

Widget _app(MemoryLearningRepository repository, ByteSource source) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repository),
      byteSourceProvider.overrideWithValue(source),
    ],
    child: MaterialApp(
      theme: appTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DownloadsScreen(),
    ),
  );
}

class _FailSource implements ByteSource {
  @override
  Future<List<int>> get(Uri uri, DownloadCancelToken token) async {
    throw StateError('offline');
  }
}

class _HoldSource implements ByteSource {
  var hold = false;

  @override
  Future<List<int>> get(Uri uri, DownloadCancelToken token) async {
    if (!hold) throw StateError('offline');
    while (!token.cancelled) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw const DownloadCancelled();
  }
}
