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

  test('age bands keep only the lessons that overlap', () {
    expect(categoriesFor(ageBand: '1-2', locale: 'en', localById: const {}), [
      'animals',
      'colors',
    ]);
    expect(categoriesFor(ageBand: '2-3', locale: 'en', localById: const {}), [
      'animals',
      'pairs',
    ]);
    expect(categoriesFor(ageBand: '3-4', locale: 'en', localById: const {}), [
      'animals',
      'sizes',
      'routines',
    ]);
    expect(categoriesFor(ageBand: '4-5', locale: 'en', localById: const {}), [
      'animals',
      'numbers',
      'routines',
    ]);
    final older = entriesForCategory(
      categoryId: 'numbers',
      manifest: const [],
      manifestFailed: true,
      localById: const {},
      ageBand: '4-5',
      locale: 'en',
    );
    expect(older.single.contentId, 'count.birds.001');
    expect(
      entriesForCategory(
        categoryId: 'colors',
        manifest: const [],
        manifestFailed: true,
        localById: const {},
        ageBand: '4-5',
        locale: 'en',
      ),
      isEmpty,
    );
  });

  test('a saved copy without English is hidden for English', () {
    const tamilOnly = StoredDocument(
      contentId: 'color.red.001',
      contentVersion: 1,
      payload: '{"contentId":"color.red.001","categoryId":"colors","ageRange":{"minMonths":12,"maxMonths":23},"localizations":{"ta":{"title":"சிவப்பு"}}}',
      payloadSha256: 'tamil',
    );
    const listed = ManifestItem(
      contentId: 'color.red.001',
      contentVersion: 1,
      categoryId: 'colors',
      title: 'Red',
      payloadSha256: 'remote',
    );
    expect(
      entriesForCategory(
        categoryId: 'colors',
        manifest: const [listed],
        manifestFailed: false,
        localById: const {'color.red.001': tamilOnly},
        ageBand: '1-2',
        locale: 'en',
      ),
      isEmpty,
    );
    final tamil = entriesForCategory(
      categoryId: 'colors',
      manifest: const [listed],
      manifestFailed: false,
      localById: const {'color.red.001': tamilOnly},
      ageBand: '1-2',
      locale: 'ta',
    );
    expect(tamil.single.title, 'சிவப்பு');
    expect(
      categoriesFor(
        ageBand: '1-2',
        locale: 'en',
        localById: const {'color.red.001': tamilOnly},
      ),
      ['animals'],
    );
  });
}
