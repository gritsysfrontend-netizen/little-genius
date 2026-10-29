import '../../data/content_api.dart';
import '../../data/records.dart';

const knownOfflineLessonId = 'animal.elephant.001';
const animalsCategoryId = 'animals';

class CatalogEntry {
  const CatalogEntry({
    required this.contentId,
    required this.title,
    required this.downloaded,
    this.contentVersion,
  });

  final String contentId;
  final String title;
  final bool downloaded;
  final int? contentVersion;
}

/// Manifest items are shown when the request succeeds.
/// The known lesson is offered only when that request fails.
List<CatalogEntry> entriesForCategory({
  required String categoryId,
  required List<ManifestItem> manifest,
  required bool manifestFailed,
  required Map<String, StoredDocument> localById,
}) {
  if (!manifestFailed) {
    return [
      for (final item in manifest)
        if (item.categoryId == categoryId)
          CatalogEntry(
            contentId: item.contentId,
            title: item.title,
            contentVersion: item.contentVersion,
            downloaded:
                localById[item.contentId]?.contentVersion ==
                    item.contentVersion &&
                localById[item.contentId]?.payloadSha256 == item.payloadSha256,
          ),
    ];
  }
  if (categoryId != animalsCategoryId) return const [];
  final local = localById[knownOfflineLessonId];
  return [
    CatalogEntry(
      contentId: knownOfflineLessonId,
      title: '',
      downloaded: local != null,
      contentVersion: local?.contentVersion,
    ),
  ];
}
