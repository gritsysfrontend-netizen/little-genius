import 'lesson_document.dart';

sealed class ParsedLesson {
  const ParsedLesson();
}

class SupportedLesson extends ParsedLesson {
  const SupportedLesson(this.document);

  final LessonDocument document;
}

class UnsupportedLesson extends ParsedLesson {
  const UnsupportedLesson(this.reason);

  final String reason;
}

const _documentKeys = {
  'schemaVersion',
  'contentId',
  'contentVersion',
  'categoryId',
  'ageRange',
  'learningObjectives',
  'difficulty',
  'estimatedDurationSeconds',
  'localizations',
  'assets',
  'interaction',
  'accessibility',
};

/// Never throws. Unknown schema versions, unknown interaction types, and
/// unknown keys become [UnsupportedLesson].
ParsedLesson parseLessonDocument(Object? input) {
  try {
    if (input is! Map) return const UnsupportedLesson('invalid');
    final json = input.map((key, value) => MapEntry(key.toString(), value));
    if (!_allowed(json, _documentKeys)) {
      return const UnsupportedLesson('invalid');
    }
    if (json['schemaVersion'] != '1.0') {
      return const UnsupportedLesson('schema');
    }
    final interaction = json['interaction'];
    if (interaction is! Map || interaction['type'] != 'tap_to_learn') {
      return const UnsupportedLesson('interaction');
    }
    if (!_allowed(interaction, {
      'type',
      'targetAssetId',
      'completionRule',
      'retryPolicy',
    })) {
      return const UnsupportedLesson('interaction');
    }
    if (!_nestedAllowed(json)) return const UnsupportedLesson('invalid');
    final document = LessonDocument.fromJson(Map<String, dynamic>.from(json));
    if (document.interaction.completionRule != 'target_tapped' ||
        document.interaction.retryPolicy != 'unlimited') {
      return const UnsupportedLesson('interaction');
    }
    return SupportedLesson(document);
  } catch (_) {
    return const UnsupportedLesson('invalid');
  }
}

bool _nestedAllowed(Map<String, dynamic> json) {
  final age = json['ageRange'];
  if (age is! Map || !_allowed(age, {'minMonths', 'maxMonths'})) return false;
  final localizations = json['localizations'];
  if (localizations is! Map || localizations.isEmpty) return false;
  for (final entry in localizations.entries) {
    if (!const {'en', 'hi', 'ta'}.contains(entry.key.toString())) return false;
    final copy = entry.value;
    if (copy is! Map ||
        !_allowed(copy, {'title', 'instruction', 'feedbackCorrect', 'audio'})) {
      return false;
    }
    final audio = copy['audio'];
    if (audio != null &&
        (audio is! Map || !_allowed(audio, {'instructionAssetId'}))) {
      return false;
    }
  }
  final assets = json['assets'];
  if (assets is! List) return false;
  for (final asset in assets) {
    if (asset is! Map || !_allowed(asset, {'assetId', 'mediaType', 'sha256'})) {
      return false;
    }
  }
  final accessibility = json['accessibility'];
  if (accessibility is! Map ||
      !_allowed(accessibility, {'imageLabel', 'requiresAudio'})) {
    return false;
  }
  final labels = accessibility['imageLabel'];
  if (labels is! Map || !_allowed(labels, {'en', 'hi', 'ta'})) return false;
  return true;
}

bool _allowed(Map<dynamic, dynamic> value, Set<String> allowed) {
  return value.keys.every((key) => allowed.contains(key.toString()));
}
