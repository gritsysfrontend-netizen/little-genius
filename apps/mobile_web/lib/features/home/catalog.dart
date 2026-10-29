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
    this.updateAvailable = false,
  });

  final String contentId;
  final String title;
  final bool downloaded;
  final int? contentVersion;

  /// A newer published version exists. The copy already open is left as it is.
  final bool updateAvailable;
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
            downloaded: _savedCopy(localById[item.contentId], item),
            updateAvailable: _newer(localById[item.contentId], item),
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

bool _savedCopy(StoredDocument? local, ManifestItem item) {
  if (local == null) return false;
  final sameVersion =
      local.contentVersion == item.contentVersion &&
      local.payloadSha256 == item.payloadSha256;
  return sameVersion || item.contentVersion > local.contentVersion;
}

bool _newer(StoredDocument? local, ManifestItem item) {
  return local != null && item.contentVersion > local.contentVersion;
}
