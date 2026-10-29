import 'dart:convert';

import '../content/canonical_json.dart';

const catalogPackId = 'pack.catalog.001';
const publishedPackSettingKey = 'published-pack';

class PackPin {
  const PackPin({
    required this.position,
    required this.contentId,
    required this.contentVersion,
    required this.payloadSha256,
  });

  final int position;
  final String contentId;
  final int contentVersion;
  final String payloadSha256;
}

class ContentPackDocument {
  const ContentPackDocument({
    required this.packId,
    required this.packVersion,
    required this.checksumSha256,
    required this.totalBytes,
    required this.minAppVersion,
    required this.items,
  });

  final String packId;
  final int packVersion;
  final String checksumSha256;
  final int totalBytes;
  final String minAppVersion;
  final List<PackPin> items;
}

/// Position order. This is the same material the API checksums.
String packMaterial(List<PackPin> items) {
  final ordered = [...items]..sort((a, b) => a.position.compareTo(b.position));
  return ordered
      .map((item) => '${item.contentId}:${item.contentVersion}\n')
      .join();
}

bool packChecksumMatches(ContentPackDocument pack) {
  return sha256Hex(utf8.encode(packMaterial(pack.items))) ==
      pack.checksumSha256;
}

/// Returns null when the document is incomplete or the checksum does not match.
ContentPackDocument? parseContentPack(Object? raw) {
  if (raw is! Map) return null;
  final packId = raw['packId'];
  final packVersion = raw['packVersion'];
  final checksum = raw['checksumSha256'];
  final totalBytes = raw['totalBytes'];
  final minAppVersion = raw['minAppVersion'];
  final rawItems = raw['items'];
  if (packId is! String ||
      packId.isEmpty ||
      packVersion is! int ||
      packVersion < 1 ||
      checksum is! String ||
      !_sha(checksum) ||
      totalBytes is! int ||
      totalBytes < 0 ||
      minAppVersion is! String ||
      minAppVersion.isEmpty ||
      rawItems is! List) {
    return null;
  }
  final items = <PackPin>[];
  final positions = <int>{};
  for (final rawItem in rawItems) {
    if (rawItem is! Map) return null;
    final position = rawItem['position'];
    final contentId = rawItem['contentId'];
    final contentVersion = rawItem['contentVersion'];
    final payloadSha256 = rawItem['payloadSha256'];
    if (position is! int ||
        position < 0 ||
        !positions.add(position) ||
        contentId is! String ||
        contentId.isEmpty ||
        contentVersion is! int ||
        contentVersion < 1 ||
        payloadSha256 is! String ||
        !_sha(payloadSha256)) {
      return null;
    }
    items.add(
      PackPin(
        position: position,
        contentId: contentId,
        contentVersion: contentVersion,
        payloadSha256: payloadSha256,
      ),
    );
  }
  final pack = ContentPackDocument(
    packId: packId,
    packVersion: packVersion,
    checksumSha256: checksum,
    totalBytes: totalBytes,
    minAppVersion: minAppVersion,
    items: items,
  );
  if (!packChecksumMatches(pack)) return null;
  return pack;
}

bool _sha(String value) => RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
