import 'dart:convert';

import '../../data/records.dart';
import '../../domain/content_pack.dart';
import '../home/catalog.dart';

class ManagedLesson {
  const ManagedLesson({
    required this.contentId,
    required this.downloaded,
    this.contentVersion,
  });

  final String contentId;
  final int? contentVersion;
  final bool downloaded;
}

class DownloadManagerSnapshot {
  const DownloadManagerSnapshot({
    required this.storageBytes,
    required this.installedPackVersion,
    required this.offline,
    required this.checksumRejected,
    required this.lessons,
  });

  final int storageBytes;
  final int? installedPackVersion;
  final bool offline;
  final bool checksumRejected;
  final List<ManagedLesson> lessons;
}

/// [fetchedJson] is the pack body from the network. A body that fails its
/// checksum is rejected, and the installed pack stays the list the parent sees.
DownloadManagerSnapshot describeDownloads({
  required int storageBytes,
  required String? installedJson,
  required String? fetchedJson,
  required bool fetchFailed,
  required List<StoredDocument> documents,
}) {
  final installed = _verified(installedJson);
  final fetched = _verified(fetchedJson);
  final checksumRejected = fetchedJson != null && fetched == null;
  final source = fetched ?? installed;
  final lessons = source == null
      ? [
          for (final known in knownLessons)
            ManagedLesson(
              contentId: known.contentId,
              downloaded: documents.any(
                (document) => document.contentId == known.contentId,
              ),
            ),
        ]
      : [
          for (final pin in [
            ...source.items,
          ]..sort((a, b) => a.position.compareTo(b.position)))
            ManagedLesson(
              contentId: pin.contentId,
              contentVersion: pin.contentVersion,
              downloaded: documents.any(
                (document) =>
                    document.contentId == pin.contentId &&
                    document.contentVersion == pin.contentVersion &&
                    document.payloadSha256 == pin.payloadSha256,
              ),
            ),
        ];
  return DownloadManagerSnapshot(
    storageBytes: storageBytes,
    installedPackVersion: installed?.packVersion,
    offline: fetchFailed,
    checksumRejected: checksumRejected,
    lessons: lessons,
  );
}

ContentPackDocument? _verified(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return parseContentPack(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}
