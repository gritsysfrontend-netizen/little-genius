import 'dart:convert';
import 'dart:typed_data';

import '../domain/content_pack.dart';
import 'content_api.dart';
import 'downloader.dart';
import 'learning_repository.dart';

class PackDownloader {
  PackDownloader({
    required this.source,
    required this.repository,
    this.baseUrl = apiBaseUrl,
  });

  final ByteSource source;
  final LearningRepository repository;
  final String baseUrl;

  /// Saves the pack only after its checksum and every pinned lesson check out.
  /// A rejected pack leaves the last saved manifest in place.
  Future<DownloadOutcome> download({
    required String packId,
    required DownloadCancelToken token,
  }) async {
    try {
      if (token.cancelled) {
        return const DownloadOutcome(DownloadStatus.cancelled);
      }
      final bytes = Uint8List.fromList(
        await source.get(
          Uri.parse('$baseUrl/api/v1/content/packs/$packId'),
          token,
        ),
      );
      final decoded = jsonDecode(utf8.decode(bytes));
      final pack = parseContentPack(decoded);
      if (pack == null || pack.packId != packId) {
        return const DownloadOutcome(DownloadStatus.checksumMismatch);
      }
      final lessons = LessonDownloader(
        source: source,
        repository: repository,
        baseUrl: baseUrl,
      );
      final pins = [...pack.items]
        ..sort((a, b) => a.position.compareTo(b.position));
      for (final pin in pins) {
        final outcome = await lessons.download(
          contentId: pin.contentId,
          token: token,
        );
        if (outcome.status != DownloadStatus.saved) return outcome;
        final saved = await repository.getDocument(
          pin.contentId,
          pin.contentVersion,
        );
        if (saved == null || saved.payloadSha256 != pin.payloadSha256) {
          return const DownloadOutcome(DownloadStatus.checksumMismatch);
        }
      }
      if (token.cancelled) {
        return const DownloadOutcome(DownloadStatus.cancelled);
      }
      await repository.setSetting(publishedPackSettingKey, utf8.decode(bytes));
      return const DownloadOutcome(DownloadStatus.saved);
    } on DownloadCancelled {
      return const DownloadOutcome(DownloadStatus.cancelled);
    } catch (_) {
      return const DownloadOutcome(DownloadStatus.failed);
    }
  }
}
