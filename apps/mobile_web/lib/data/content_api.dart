import 'dart:convert';

import 'downloader.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3000',
);

class ManifestItem {
  const ManifestItem({
    required this.contentId,
    required this.contentVersion,
    required this.categoryId,
    required this.title,
    required this.payloadSha256,
  });

  final String contentId;
  final int contentVersion;
  final String categoryId;
  final String title;
  final String payloadSha256;
}

class ContentApi {
  ContentApi(this.source, {this.baseUrl = apiBaseUrl});

  final ByteSource source;
  final String baseUrl;

  Future<List<ManifestItem>> manifest({
    required String locale,
    required String ageBand,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/content/manifest')
        .replace(queryParameters: {'locale': locale, 'ageBand': ageBand});
    final decoded = _object(
      utf8.decode(await source.get(uri, DownloadCancelToken())),
    );
    final items = decoded['items'];
    if (items is! List) throw const FormatException('manifest');
    return [
      for (final item in items)
        if (item is Map)
          ManifestItem(
            contentId: item['contentId'] as String,
            contentVersion: item['contentVersion'] as int,
            categoryId: item['categoryId'] as String,
            title: item['title'] as String,
            payloadSha256: item['payloadSha256'] as String,
          ),
    ];
  }
}

Map<String, Object?> _object(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) throw const FormatException('json');
  return decoded.map(
    (key, value) => MapEntry(key.toString(), value as Object?),
  );
}
