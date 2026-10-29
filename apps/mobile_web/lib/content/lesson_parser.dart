import 'lesson_document.dart';
import 'lesson_interaction.dart';

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

const _localeCodes = {'en', 'hi', 'ta'};

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
    if (!_nestedAllowed(json)) return const UnsupportedLesson('invalid');
    final locales = _declaredLocales(json);
    if (locales.isEmpty) return const UnsupportedLesson('invalid');
    final interaction = tryParseInteraction(
      json['interaction'],
      requiredLocales: locales,
    );
    if (interaction == null) return const UnsupportedLesson('interaction');
    if (interaction is! TapToLearn && !_retryCopy(json, locales)) {
      return const UnsupportedLesson('interaction');
    }
    final document = LessonDocument.fromJson(Map<String, dynamic>.from(json));
    return SupportedLesson(document);
  } catch (_) {
    return const UnsupportedLesson('invalid');
  }
}

Set<String> _declaredLocales(Map<String, dynamic> json) {
  final localizations = json['localizations'];
  if (localizations is! Map) return const {};
  return {
    for (final key in localizations.keys.map((key) => key.toString()))
      if (_localeCodes.contains(key)) key,
  };
}

bool _retryCopy(Map<String, dynamic> json, Set<String> locales) {
  final localizations = json['localizations'];
  if (localizations is! Map) return false;
  for (final code in locales) {
    final copy = localizations[code];
    if (copy is! Map) return false;
    final retry = copy['feedbackRetry'];
    if (retry is! String || retry.isEmpty || retry.length > 80) return false;
  }
  return true;
}

bool _nestedAllowed(Map<String, dynamic> json) {
  final age = json['ageRange'];
  if (age is! Map || !_allowed(age, {'minMonths', 'maxMonths'})) return false;
  final localizations = json['localizations'];
  if (localizations is! Map || localizations.isEmpty) return false;
  for (final entry in localizations.entries) {
    if (!_localeCodes.contains(entry.key.toString())) return false;
    final copy = entry.value;
    if (copy is! Map ||
        !_allowed(copy, {
          'title',
          'instruction',
          'feedbackCorrect',
          'feedbackRetry',
          'audio',
        })) {
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
  if (labels is! Map || !_allowed(labels, _localeCodes)) return false;
  return true;
}

bool _allowed(Map<dynamic, dynamic> value, Set<String> allowed) {
  return value.keys.every((key) => allowed.contains(key.toString()));
}
