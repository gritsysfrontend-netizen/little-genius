// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonDocument _$LessonDocumentFromJson(Map<String, dynamic> json) =>
    _LessonDocument(
      schemaVersion: json['schemaVersion'] as String,
      contentId: json['contentId'] as String,
      contentVersion: (json['contentVersion'] as num).toInt(),
      categoryId: json['categoryId'] as String,
      ageRange: AgeRange.fromJson(json['ageRange'] as Map<String, dynamic>),
      learningObjectives: (json['learningObjectives'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      difficulty: (json['difficulty'] as num).toInt(),
      estimatedDurationSeconds: (json['estimatedDurationSeconds'] as num)
          .toInt(),
      localizations: (json['localizations'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, LessonLocalization.fromJson(e as Map<String, dynamic>)),
      ),
      assets: (json['assets'] as List<dynamic>)
          .map((e) => AssetRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      interaction: readInteraction(json['interaction']),
      accessibility: LessonAccessibility.fromJson(
        json['accessibility'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$LessonDocumentToJson(_LessonDocument instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'contentId': instance.contentId,
      'contentVersion': instance.contentVersion,
      'categoryId': instance.categoryId,
      'ageRange': instance.ageRange.toJson(),
      'learningObjectives': instance.learningObjectives,
      'difficulty': instance.difficulty,
      'estimatedDurationSeconds': instance.estimatedDurationSeconds,
      'localizations': instance.localizations.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
      'assets': instance.assets.map((e) => e.toJson()).toList(),
      'interaction': writeInteraction(instance.interaction),
      'accessibility': instance.accessibility.toJson(),
    };

_AgeRange _$AgeRangeFromJson(Map<String, dynamic> json) => _AgeRange(
  minMonths: (json['minMonths'] as num).toInt(),
  maxMonths: (json['maxMonths'] as num).toInt(),
);

Map<String, dynamic> _$AgeRangeToJson(_AgeRange instance) => <String, dynamic>{
  'minMonths': instance.minMonths,
  'maxMonths': instance.maxMonths,
};

_LessonLocalization _$LessonLocalizationFromJson(Map<String, dynamic> json) =>
    _LessonLocalization(
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      feedbackCorrect: json['feedbackCorrect'] as String,
      feedbackRetry: json['feedbackRetry'] as String?,
      audio: json['audio'] == null
          ? null
          : LessonAudio.fromJson(json['audio'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LessonLocalizationToJson(_LessonLocalization instance) =>
    <String, dynamic>{
      'title': instance.title,
      'instruction': instance.instruction,
      'feedbackCorrect': instance.feedbackCorrect,
      'feedbackRetry': instance.feedbackRetry,
      'audio': instance.audio?.toJson(),
    };

_LessonAudio _$LessonAudioFromJson(Map<String, dynamic> json) =>
    _LessonAudio(instructionAssetId: json['instructionAssetId'] as String?);

Map<String, dynamic> _$LessonAudioToJson(_LessonAudio instance) =>
    <String, dynamic>{'instructionAssetId': instance.instructionAssetId};

_AssetRef _$AssetRefFromJson(Map<String, dynamic> json) => _AssetRef(
  assetId: json['assetId'] as String,
  mediaType: json['mediaType'] as String,
  sha256: json['sha256'] as String,
);

Map<String, dynamic> _$AssetRefToJson(_AssetRef instance) => <String, dynamic>{
  'assetId': instance.assetId,
  'mediaType': instance.mediaType,
  'sha256': instance.sha256,
};

_LessonAccessibility _$LessonAccessibilityFromJson(Map<String, dynamic> json) =>
    _LessonAccessibility(
      imageLabel: Map<String, String>.from(json['imageLabel'] as Map),
      requiresAudio: json['requiresAudio'] as bool,
    );

Map<String, dynamic> _$LessonAccessibilityToJson(
  _LessonAccessibility instance,
) => <String, dynamic>{
  'imageLabel': instance.imageLabel,
  'requiresAudio': instance.requiresAudio,
};
