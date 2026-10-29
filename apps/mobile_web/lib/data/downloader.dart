import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../content/canonical_json.dart';
import '../content/lesson_document.dart';
import '../content/lesson_parser.dart';
import 'content_api.dart';
import 'learning_repository.dart';
import 'records.dart';

class DownloadCancelToken {
  bool cancelled = false;
  void Function()? _onCancel;

  void bind(void Function() onCancel) => _onCancel = onCancel;

  void cancel() {
    cancelled = true;
    _onCancel?.call();
  }
}

class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

enum DownloadStatus { saved, cancelled, checksumMismatch, failed }

class DownloadOutcome {
  const DownloadOutcome(this.status);

  final DownloadStatus status;
}

abstract class ByteSource {
  Future<List<int>> get(Uri uri, DownloadCancelToken token);
}

class DioByteSource implements ByteSource {
  DioByteSource(this.dio);

  final Dio dio;

  @override
  Future<List<int>> get(Uri uri, DownloadCancelToken token) async {
    if (token.cancelled) throw const DownloadCancelled();
    final cancel = CancelToken();
    token.bind(cancel.cancel);
    try {
      final response = await dio.getUri<List<int>>(
        uri,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      if (token.cancelled) throw const DownloadCancelled();
      return response.data ?? const [];
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || token.cancelled) {
        throw const DownloadCancelled();
      }
      rethrow;
    }
  }
}

class LessonDownloader {
  LessonDownloader({
    required this.source,
    required this.repository,
    this.baseUrl = apiBaseUrl,
  });

  final ByteSource source;
  final LearningRepository repository;
  final String baseUrl;

  Future<DownloadOutcome> download({
    required String contentId,
    required DownloadCancelToken token,
  }) async {
    try {
      final pointer = await _json(
        Uri.parse('$baseUrl/api/v1/content/$contentId'),
        token,
      );
      final version = pointer['contentVersion'];
      final expected = pointer['payloadSha256'];
      if (pointer['contentId'] != contentId ||
          version is! int ||
          expected is! String) {
        return const DownloadOutcome(DownloadStatus.failed);
      }
      final lessonBytes = Uint8List.fromList(
        await source.get(
          Uri.parse('$baseUrl/api/v1/content/$contentId/versions/$version'),
          token,
        ),
      );
      if (sha256Hex(lessonBytes) != expected) {
        return const DownloadOutcome(DownloadStatus.checksumMismatch);
      }
      final parsed = parseLessonDocument(jsonDecode(utf8.decode(lessonBytes)));
      if (parsed is! SupportedLesson ||
          parsed.document.contentVersion != version) {
        return const DownloadOutcome(DownloadStatus.failed);
      }
      final pending = <StoredBlob>[];
      for (final asset in parsed.document.assets) {
        final blob = await _asset(asset, token);
        if (blob == null) {
          return const DownloadOutcome(DownloadStatus.checksumMismatch);
        }
        pending.add(blob);
      }
      if (token.cancelled) {
        return const DownloadOutcome(DownloadStatus.cancelled);
      }
      for (final blob in pending) {
        await repository.saveBlob(blob);
      }
      await repository.saveDocument(
        StoredDocument(
          contentId: parsed.document.contentId,
          contentVersion: version,
          payload: utf8.decode(lessonBytes),
          payloadSha256: expected,
        ),
      );
      return const DownloadOutcome(DownloadStatus.saved);
    } on DownloadCancelled {
      return const DownloadOutcome(DownloadStatus.cancelled);
    } catch (_) {
      return const DownloadOutcome(DownloadStatus.failed);
    }
  }

  Future<StoredBlob?> _asset(AssetRef asset, DownloadCancelToken token) async {
    final descriptor = await _json(
      Uri.parse('$baseUrl/api/v1/assets/${asset.assetId}'),
      token,
    );
    final url = descriptor['url'];
    final declared = descriptor['sha256'];
    final size = descriptor['byteSize'];
    final mediaType = descriptor['mediaType'];
    if (url is! String ||
        declared is! String ||
        mediaType is! String ||
        declared != asset.sha256) {
      return null;
    }
    final bytes = Uint8List.fromList(await source.get(Uri.parse(url), token));
    if (sha256Hex(bytes) != asset.sha256) return null;
    if (size is int && size != bytes.length) return null;
    return StoredBlob(
      assetId: asset.assetId,
      sha256: asset.sha256,
      mediaType: mediaType,
      bytes: bytes,
    );
  }

  Future<Map<String, Object?>> _json(Uri uri, DownloadCancelToken token) async {
    final decoded = jsonDecode(utf8.decode(await source.get(uri, token)));
    if (decoded is! Map) throw const FormatException('json');
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value as Object?),
    );
  }
}
