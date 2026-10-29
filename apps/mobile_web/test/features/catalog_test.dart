import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/data/content_api.dart';
import 'package:little_genius/data/records.dart';
import 'package:little_genius/features/home/catalog.dart';

void main() {
  const item = ManifestItem(
    contentId: 'animal.elephant.001',
    contentVersion: 2,
    categoryId: 'animals',
    title: 'Elephant',
    payloadSha256: 'new',
  );
  const saved = StoredDocument(
    contentId: 'animal.elephant.001',
    contentVersion: 1,
    payload: '{}',
    payloadSha256: 'old',
  );

  test('a newer manifest leaves the saved copy playable', () {
    final entries = entriesForCategory(
      categoryId: 'animals',
      manifest: const [item],
      manifestFailed: false,
      localById: const {'animal.elephant.001': saved},
    );
    expect(entries.single.downloaded, isTrue);
    expect(entries.single.updateAvailable, isTrue);
    expect(entries.single.title, 'Elephant');
  });

  test('the same saved version is not marked as an update', () {
    const current = ManifestItem(
      contentId: 'animal.elephant.001',
      contentVersion: 1,
      categoryId: 'animals',
      title: 'Elephant',
      payloadSha256: 'old',
    );
    final entries = entriesForCategory(
      categoryId: 'animals',
      manifest: const [current],
      manifestFailed: false,
      localById: const {'animal.elephant.001': saved},
    );
    expect(entries.single.downloaded, isTrue);
    expect(entries.single.updateAvailable, isFalse);
  });

  test('a failed manifest does not invent an update', () {
    final entries = entriesForCategory(
      categoryId: 'animals',
      manifest: const [],
      manifestFailed: true,
      localById: const {'animal.elephant.001': saved},
    );
    expect(entries.single.updateAvailable, isFalse);
    expect(entries.single.downloaded, isTrue);
  });
}
