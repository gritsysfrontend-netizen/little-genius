import 'dart:convert';
import 'dart:typed_data';

import '../domain/progress_rules.dart';

class StoredDocument {
  const StoredDocument({
    required this.contentId,
    required this.contentVersion,
    required this.payload,
    required this.payloadSha256,
  });

  final String contentId;
  final int contentVersion;
  final String payload;
  final String payloadSha256;
}

class StoredBlob {
  const StoredBlob({
    required this.assetId,
    required this.sha256,
    required this.mediaType,
    required this.bytes,
  });

  final String assetId;
  final String sha256;
  final String mediaType;
  final Uint8List bytes;
}

class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.profileId,
    required this.idempotencyKey,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final String profileId;
  final String idempotencyKey;
  final String body;
  final String createdAt;
}

class ApplyResult {
  const ApplyResult({required this.inserted, required this.summary});

  final bool inserted;
  final ProgressSummary summary;
}

String eventBatchBody(LearningEvent event) {
  return jsonEncode({
    'events': [event.toJson()],
  });
}
