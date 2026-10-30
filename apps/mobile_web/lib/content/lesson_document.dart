import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson_document.freezed.dart';
part 'lesson_document.g.dart';

@freezed
abstract class LessonDocument with _$LessonDocument {
  const factory LessonDocument({
    required String schemaVersion,
    required String contentId,
    required int contentVersion,
    required String categoryId,
    required AgeRange ageRange,
    required List<String> learningObjectives,
    required int difficulty,
    required int estimatedDurationSeconds,
    required Map<String, LessonLocalization> localizations,
    required List<AssetRef> assets,
    required TapToLearn interaction,
    required LessonAccessibility accessibility,
  }) = _LessonDocument;

  factory LessonDocument.fromJson(Map<String, dynamic> json) =>
      _$LessonDocumentFromJson(json);
}

@freezed
abstract class AgeRange with _$AgeRange {
  const factory AgeRange({required int minMonths, required int maxMonths}) =
      _AgeRange;

  factory AgeRange.fromJson(Map<String, dynamic> json) =>
      _$AgeRangeFromJson(json);
}

@freezed
abstract class LessonLocalization with _$LessonLocalization {
  const factory LessonLocalization({
    required String title,
    required String instruction,
    required String feedbackCorrect,
    LessonAudio? audio,
  }) = _LessonLocalization;

  factory LessonLocalization.fromJson(Map<String, dynamic> json) =>
      _$LessonLocalizationFromJson(json);
}

@freezed
abstract class LessonAudio with _$LessonAudio {
  const factory LessonAudio({String? instructionAssetId}) = _LessonAudio;

  factory LessonAudio.fromJson(Map<String, dynamic> json) =>
      _$LessonAudioFromJson(json);
}

@freezed
abstract class AssetRef with _$AssetRef {
  const factory AssetRef({
    required String assetId,
    required String mediaType,
    required String sha256,
  }) = _AssetRef;

  factory AssetRef.fromJson(Map<String, dynamic> json) =>
      _$AssetRefFromJson(json);
}

@freezed
abstract class TapToLearn with _$TapToLearn {
  const factory TapToLearn({
    required String type,
    required String targetAssetId,
    required String completionRule,
    required String retryPolicy,
  }) = _TapToLearn;

  factory TapToLearn.fromJson(Map<String, dynamic> json) =>
      _$TapToLearnFromJson(json);
}

@freezed
abstract class LessonAccessibility with _$LessonAccessibility {
  const factory LessonAccessibility({
    required Map<String, String> imageLabel,
    required bool requiresAudio,
  }) = _LessonAccessibility;

  factory LessonAccessibility.fromJson(Map<String, dynamic> json) =>
      _$LessonAccessibilityFromJson(json);
}
