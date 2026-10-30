// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LessonDocument {

 String get schemaVersion; String get contentId; int get contentVersion; String get categoryId; AgeRange get ageRange; List<String> get learningObjectives; int get difficulty; int get estimatedDurationSeconds; Map<String, LessonLocalization> get localizations; List<AssetRef> get assets; TapToLearn get interaction; LessonAccessibility get accessibility;
/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonDocumentCopyWith<LessonDocument> get copyWith => _$LessonDocumentCopyWithImpl<LessonDocument>(this as LessonDocument, _$identity);

  /// Serializes this LessonDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LessonDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonDocument&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&(identical(other.contentId, _this.contentId) || other.contentId == _this.contentId)&&(identical(other.contentVersion, _this.contentVersion) || other.contentVersion == _this.contentVersion)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.ageRange, _this.ageRange) || other.ageRange == _this.ageRange)&&const DeepCollectionEquality().equals(other.learningObjectives, _this.learningObjectives)&&(identical(other.difficulty, _this.difficulty) || other.difficulty == _this.difficulty)&&(identical(other.estimatedDurationSeconds, _this.estimatedDurationSeconds) || other.estimatedDurationSeconds == _this.estimatedDurationSeconds)&&const DeepCollectionEquality().equals(other.localizations, _this.localizations)&&const DeepCollectionEquality().equals(other.assets, _this.assets)&&(identical(other.interaction, _this.interaction) || other.interaction == _this.interaction)&&(identical(other.accessibility, _this.accessibility) || other.accessibility == _this.accessibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LessonDocument;
  return Object.hash(runtimeType,_this.schemaVersion,_this.contentId,_this.contentVersion,_this.categoryId,_this.ageRange,const DeepCollectionEquality().hash(_this.learningObjectives),_this.difficulty,_this.estimatedDurationSeconds,const DeepCollectionEquality().hash(_this.localizations),const DeepCollectionEquality().hash(_this.assets),_this.interaction,_this.accessibility);
}

@override
String toString() {
  final _this = this as LessonDocument;
  return 'LessonDocument(schemaVersion: ${_this.schemaVersion}, contentId: ${_this.contentId}, contentVersion: ${_this.contentVersion}, categoryId: ${_this.categoryId}, ageRange: ${_this.ageRange}, learningObjectives: ${_this.learningObjectives}, difficulty: ${_this.difficulty}, estimatedDurationSeconds: ${_this.estimatedDurationSeconds}, localizations: ${_this.localizations}, assets: ${_this.assets}, interaction: ${_this.interaction}, accessibility: ${_this.accessibility})';
}


}

/// @nodoc
abstract mixin class $LessonDocumentCopyWith<$Res>  {
  factory $LessonDocumentCopyWith(LessonDocument value, $Res Function(LessonDocument) _then) = _$LessonDocumentCopyWithImpl;
@useResult
$Res call({
 String schemaVersion, String contentId, int contentVersion, String categoryId, AgeRange ageRange, List<String> learningObjectives, int difficulty, int estimatedDurationSeconds, Map<String, LessonLocalization> localizations, List<AssetRef> assets, TapToLearn interaction, LessonAccessibility accessibility
});


$AgeRangeCopyWith<$Res> get ageRange;$TapToLearnCopyWith<$Res> get interaction;$LessonAccessibilityCopyWith<$Res> get accessibility;

}
/// @nodoc
class _$LessonDocumentCopyWithImpl<$Res>
    implements $LessonDocumentCopyWith<$Res> {
  _$LessonDocumentCopyWithImpl(this._self, this._then);

  final LessonDocument _self;
  final $Res Function(LessonDocument) _then;

/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? contentId = null,Object? contentVersion = null,Object? categoryId = null,Object? ageRange = null,Object? learningObjectives = null,Object? difficulty = null,Object? estimatedDurationSeconds = null,Object? localizations = null,Object? assets = null,Object? interaction = null,Object? accessibility = null,}) {
  return _then(LessonDocument(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as String,contentId: null == contentId ? _self.contentId : contentId // ignore: cast_nullable_to_non_nullable
as String,contentVersion: null == contentVersion ? _self.contentVersion : contentVersion // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,ageRange: null == ageRange ? _self.ageRange : ageRange // ignore: cast_nullable_to_non_nullable
as AgeRange,learningObjectives: null == learningObjectives ? _self.learningObjectives : learningObjectives // ignore: cast_nullable_to_non_nullable
as List<String>,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationSeconds: null == estimatedDurationSeconds ? _self.estimatedDurationSeconds : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,localizations: null == localizations ? _self.localizations : localizations // ignore: cast_nullable_to_non_nullable
as Map<String, LessonLocalization>,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<AssetRef>,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as TapToLearn,accessibility: null == accessibility ? _self.accessibility : accessibility // ignore: cast_nullable_to_non_nullable
as LessonAccessibility,
  ));
}
/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgeRangeCopyWith<$Res> get ageRange {
  
  return $AgeRangeCopyWith<$Res>(_self.ageRange, (value) {
    return _then(_self.copyWith(ageRange: value));
  });
}/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TapToLearnCopyWith<$Res> get interaction {
  
  return $TapToLearnCopyWith<$Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonAccessibilityCopyWith<$Res> get accessibility {
  
  return $LessonAccessibilityCopyWith<$Res>(_self.accessibility, (value) {
    return _then(_self.copyWith(accessibility: value));
  });
}
}


/// Adds pattern-matching-related methods to [LessonDocument].
extension LessonDocumentPatterns on LessonDocument {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonDocument() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonDocument value)  $default,){
final _that = this;
switch (_that) {
case _LessonDocument():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonDocument value)?  $default,){
final _that = this;
switch (_that) {
case _LessonDocument() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schemaVersion,  String contentId,  int contentVersion,  String categoryId,  AgeRange ageRange,  List<String> learningObjectives,  int difficulty,  int estimatedDurationSeconds,  Map<String, LessonLocalization> localizations,  List<AssetRef> assets,  TapToLearn interaction,  LessonAccessibility accessibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonDocument() when $default != null:
return $default(_that.schemaVersion,_that.contentId,_that.contentVersion,_that.categoryId,_that.ageRange,_that.learningObjectives,_that.difficulty,_that.estimatedDurationSeconds,_that.localizations,_that.assets,_that.interaction,_that.accessibility);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schemaVersion,  String contentId,  int contentVersion,  String categoryId,  AgeRange ageRange,  List<String> learningObjectives,  int difficulty,  int estimatedDurationSeconds,  Map<String, LessonLocalization> localizations,  List<AssetRef> assets,  TapToLearn interaction,  LessonAccessibility accessibility)  $default,) {final _that = this;
switch (_that) {
case _LessonDocument():
return $default(_that.schemaVersion,_that.contentId,_that.contentVersion,_that.categoryId,_that.ageRange,_that.learningObjectives,_that.difficulty,_that.estimatedDurationSeconds,_that.localizations,_that.assets,_that.interaction,_that.accessibility);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schemaVersion,  String contentId,  int contentVersion,  String categoryId,  AgeRange ageRange,  List<String> learningObjectives,  int difficulty,  int estimatedDurationSeconds,  Map<String, LessonLocalization> localizations,  List<AssetRef> assets,  TapToLearn interaction,  LessonAccessibility accessibility)?  $default,) {final _that = this;
switch (_that) {
case _LessonDocument() when $default != null:
return $default(_that.schemaVersion,_that.contentId,_that.contentVersion,_that.categoryId,_that.ageRange,_that.learningObjectives,_that.difficulty,_that.estimatedDurationSeconds,_that.localizations,_that.assets,_that.interaction,_that.accessibility);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonDocument implements LessonDocument {
  const _LessonDocument({required this.schemaVersion, required this.contentId, required this.contentVersion, required this.categoryId, required this.ageRange, required  List<String> learningObjectives, required this.difficulty, required this.estimatedDurationSeconds, required  Map<String, LessonLocalization> localizations, required  List<AssetRef> assets, required this.interaction, required this.accessibility}): _learningObjectives = learningObjectives,_localizations = localizations,_assets = assets;
  factory _LessonDocument.fromJson(Map<String, dynamic> json) => _$LessonDocumentFromJson(json);

@override final  String schemaVersion;
@override final  String contentId;
@override final  int contentVersion;
@override final  String categoryId;
@override final  AgeRange ageRange;
 final  List<String> _learningObjectives;
@override List<String> get learningObjectives {
  if (_learningObjectives is EqualUnmodifiableListView) return _learningObjectives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_learningObjectives);
}

@override final  int difficulty;
@override final  int estimatedDurationSeconds;
 final  Map<String, LessonLocalization> _localizations;
@override Map<String, LessonLocalization> get localizations {
  if (_localizations is EqualUnmodifiableMapView) return _localizations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_localizations);
}

 final  List<AssetRef> _assets;
@override List<AssetRef> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}

@override final  TapToLearn interaction;
@override final  LessonAccessibility accessibility;

/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonDocumentCopyWith<_LessonDocument> get copyWith => __$LessonDocumentCopyWithImpl<_LessonDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonDocument&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.contentId, contentId) || other.contentId == contentId)&&(identical(other.contentVersion, contentVersion) || other.contentVersion == contentVersion)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.ageRange, ageRange) || other.ageRange == ageRange)&&const DeepCollectionEquality().equals(other.learningObjectives, _learningObjectives)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.estimatedDurationSeconds, estimatedDurationSeconds) || other.estimatedDurationSeconds == estimatedDurationSeconds)&&const DeepCollectionEquality().equals(other.localizations, _localizations)&&const DeepCollectionEquality().equals(other.assets, _assets)&&(identical(other.interaction, interaction) || other.interaction == interaction)&&(identical(other.accessibility, accessibility) || other.accessibility == accessibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,schemaVersion,contentId,contentVersion,categoryId,ageRange,const DeepCollectionEquality().hash(_learningObjectives),difficulty,estimatedDurationSeconds,const DeepCollectionEquality().hash(_localizations),const DeepCollectionEquality().hash(_assets),interaction,accessibility);
}

@override
String toString() {
    return 'LessonDocument(schemaVersion: $schemaVersion, contentId: $contentId, contentVersion: $contentVersion, categoryId: $categoryId, ageRange: $ageRange, learningObjectives: $learningObjectives, difficulty: $difficulty, estimatedDurationSeconds: $estimatedDurationSeconds, localizations: $localizations, assets: $assets, interaction: $interaction, accessibility: $accessibility)';
}


}

/// @nodoc
abstract mixin class _$LessonDocumentCopyWith<$Res> implements $LessonDocumentCopyWith<$Res> {
  factory _$LessonDocumentCopyWith(_LessonDocument value, $Res Function(_LessonDocument) _then) = __$LessonDocumentCopyWithImpl;
@override @useResult
$Res call({
 String schemaVersion, String contentId, int contentVersion, String categoryId, AgeRange ageRange, List<String> learningObjectives, int difficulty, int estimatedDurationSeconds, Map<String, LessonLocalization> localizations, List<AssetRef> assets, TapToLearn interaction, LessonAccessibility accessibility
});


@override $AgeRangeCopyWith<$Res> get ageRange;@override $TapToLearnCopyWith<$Res> get interaction;@override $LessonAccessibilityCopyWith<$Res> get accessibility;

}
/// @nodoc
class __$LessonDocumentCopyWithImpl<$Res>
    implements _$LessonDocumentCopyWith<$Res> {
  __$LessonDocumentCopyWithImpl(this._self, this._then);

  final _LessonDocument _self;
  final $Res Function(_LessonDocument) _then;

/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? contentId = null,Object? contentVersion = null,Object? categoryId = null,Object? ageRange = null,Object? learningObjectives = null,Object? difficulty = null,Object? estimatedDurationSeconds = null,Object? localizations = null,Object? assets = null,Object? interaction = null,Object? accessibility = null,}) {
  return _then(_LessonDocument(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as String,contentId: null == contentId ? _self.contentId : contentId // ignore: cast_nullable_to_non_nullable
as String,contentVersion: null == contentVersion ? _self.contentVersion : contentVersion // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,ageRange: null == ageRange ? _self.ageRange : ageRange // ignore: cast_nullable_to_non_nullable
as AgeRange,learningObjectives: null == learningObjectives ? _self._learningObjectives : learningObjectives // ignore: cast_nullable_to_non_nullable
as List<String>,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationSeconds: null == estimatedDurationSeconds ? _self.estimatedDurationSeconds : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,localizations: null == localizations ? _self._localizations : localizations // ignore: cast_nullable_to_non_nullable
as Map<String, LessonLocalization>,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<AssetRef>,interaction: null == interaction ? _self.interaction : interaction // ignore: cast_nullable_to_non_nullable
as TapToLearn,accessibility: null == accessibility ? _self.accessibility : accessibility // ignore: cast_nullable_to_non_nullable
as LessonAccessibility,
  ));
}

/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AgeRangeCopyWith<$Res> get ageRange {
  
  return $AgeRangeCopyWith<$Res>(_self.ageRange, (value) {
    return _then(_self.copyWith(ageRange: value));
  });
}/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TapToLearnCopyWith<$Res> get interaction {
  
  return $TapToLearnCopyWith<$Res>(_self.interaction, (value) {
    return _then(_self.copyWith(interaction: value));
  });
}/// Create a copy of LessonDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonAccessibilityCopyWith<$Res> get accessibility {
  
  return $LessonAccessibilityCopyWith<$Res>(_self.accessibility, (value) {
    return _then(_self.copyWith(accessibility: value));
  });
}
}


/// @nodoc
mixin _$AgeRange {

 int get minMonths; int get maxMonths;
/// Create a copy of AgeRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgeRangeCopyWith<AgeRange> get copyWith => _$AgeRangeCopyWithImpl<AgeRange>(this as AgeRange, _$identity);

  /// Serializes this AgeRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AgeRange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgeRange&&(identical(other.minMonths, _this.minMonths) || other.minMonths == _this.minMonths)&&(identical(other.maxMonths, _this.maxMonths) || other.maxMonths == _this.maxMonths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AgeRange;
  return Object.hash(runtimeType,_this.minMonths,_this.maxMonths);
}

@override
String toString() {
  final _this = this as AgeRange;
  return 'AgeRange(minMonths: ${_this.minMonths}, maxMonths: ${_this.maxMonths})';
}


}

/// @nodoc
abstract mixin class $AgeRangeCopyWith<$Res>  {
  factory $AgeRangeCopyWith(AgeRange value, $Res Function(AgeRange) _then) = _$AgeRangeCopyWithImpl;
@useResult
$Res call({
 int minMonths, int maxMonths
});




}
/// @nodoc
class _$AgeRangeCopyWithImpl<$Res>
    implements $AgeRangeCopyWith<$Res> {
  _$AgeRangeCopyWithImpl(this._self, this._then);

  final AgeRange _self;
  final $Res Function(AgeRange) _then;

/// Create a copy of AgeRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minMonths = null,Object? maxMonths = null,}) {
  return _then(AgeRange(
minMonths: null == minMonths ? _self.minMonths : minMonths // ignore: cast_nullable_to_non_nullable
as int,maxMonths: null == maxMonths ? _self.maxMonths : maxMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AgeRange].
extension AgeRangePatterns on AgeRange {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgeRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgeRange() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgeRange value)  $default,){
final _that = this;
switch (_that) {
case _AgeRange():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgeRange value)?  $default,){
final _that = this;
switch (_that) {
case _AgeRange() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minMonths,  int maxMonths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgeRange() when $default != null:
return $default(_that.minMonths,_that.maxMonths);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minMonths,  int maxMonths)  $default,) {final _that = this;
switch (_that) {
case _AgeRange():
return $default(_that.minMonths,_that.maxMonths);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minMonths,  int maxMonths)?  $default,) {final _that = this;
switch (_that) {
case _AgeRange() when $default != null:
return $default(_that.minMonths,_that.maxMonths);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgeRange implements AgeRange {
  const _AgeRange({required this.minMonths, required this.maxMonths});
  factory _AgeRange.fromJson(Map<String, dynamic> json) => _$AgeRangeFromJson(json);

@override final  int minMonths;
@override final  int maxMonths;

/// Create a copy of AgeRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgeRangeCopyWith<_AgeRange> get copyWith => __$AgeRangeCopyWithImpl<_AgeRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgeRangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgeRange&&(identical(other.minMonths, minMonths) || other.minMonths == minMonths)&&(identical(other.maxMonths, maxMonths) || other.maxMonths == maxMonths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,minMonths,maxMonths);
}

@override
String toString() {
    return 'AgeRange(minMonths: $minMonths, maxMonths: $maxMonths)';
}


}

/// @nodoc
abstract mixin class _$AgeRangeCopyWith<$Res> implements $AgeRangeCopyWith<$Res> {
  factory _$AgeRangeCopyWith(_AgeRange value, $Res Function(_AgeRange) _then) = __$AgeRangeCopyWithImpl;
@override @useResult
$Res call({
 int minMonths, int maxMonths
});




}
/// @nodoc
class __$AgeRangeCopyWithImpl<$Res>
    implements _$AgeRangeCopyWith<$Res> {
  __$AgeRangeCopyWithImpl(this._self, this._then);

  final _AgeRange _self;
  final $Res Function(_AgeRange) _then;

/// Create a copy of AgeRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minMonths = null,Object? maxMonths = null,}) {
  return _then(_AgeRange(
minMonths: null == minMonths ? _self.minMonths : minMonths // ignore: cast_nullable_to_non_nullable
as int,maxMonths: null == maxMonths ? _self.maxMonths : maxMonths // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LessonLocalization {

 String get title; String get instruction; String get feedbackCorrect; LessonAudio? get audio;
/// Create a copy of LessonLocalization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonLocalizationCopyWith<LessonLocalization> get copyWith => _$LessonLocalizationCopyWithImpl<LessonLocalization>(this as LessonLocalization, _$identity);

  /// Serializes this LessonLocalization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LessonLocalization;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonLocalization&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.instruction, _this.instruction) || other.instruction == _this.instruction)&&(identical(other.feedbackCorrect, _this.feedbackCorrect) || other.feedbackCorrect == _this.feedbackCorrect)&&(identical(other.audio, _this.audio) || other.audio == _this.audio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LessonLocalization;
  return Object.hash(runtimeType,_this.title,_this.instruction,_this.feedbackCorrect,_this.audio);
}

@override
String toString() {
  final _this = this as LessonLocalization;
  return 'LessonLocalization(title: ${_this.title}, instruction: ${_this.instruction}, feedbackCorrect: ${_this.feedbackCorrect}, audio: ${_this.audio})';
}


}

/// @nodoc
abstract mixin class $LessonLocalizationCopyWith<$Res>  {
  factory $LessonLocalizationCopyWith(LessonLocalization value, $Res Function(LessonLocalization) _then) = _$LessonLocalizationCopyWithImpl;
@useResult
$Res call({
 String title, String instruction, String feedbackCorrect, LessonAudio? audio
});


$LessonAudioCopyWith<$Res>? get audio;

}
/// @nodoc
class _$LessonLocalizationCopyWithImpl<$Res>
    implements $LessonLocalizationCopyWith<$Res> {
  _$LessonLocalizationCopyWithImpl(this._self, this._then);

  final LessonLocalization _self;
  final $Res Function(LessonLocalization) _then;

/// Create a copy of LessonLocalization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? instruction = null,Object? feedbackCorrect = null,Object? audio = freezed,}) {
  return _then(LessonLocalization(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as String,feedbackCorrect: null == feedbackCorrect ? _self.feedbackCorrect : feedbackCorrect // ignore: cast_nullable_to_non_nullable
as String,audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as LessonAudio?,
  ));
}
/// Create a copy of LessonLocalization
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonAudioCopyWith<$Res>? get audio {
    if (_self.audio == null) {
    return null;
  }

  return $LessonAudioCopyWith<$Res>(_self.audio!, (value) {
    return _then(_self.copyWith(audio: value));
  });
}
}


/// Adds pattern-matching-related methods to [LessonLocalization].
extension LessonLocalizationPatterns on LessonLocalization {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonLocalization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonLocalization() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonLocalization value)  $default,){
final _that = this;
switch (_that) {
case _LessonLocalization():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonLocalization value)?  $default,){
final _that = this;
switch (_that) {
case _LessonLocalization() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String instruction,  String feedbackCorrect,  LessonAudio? audio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonLocalization() when $default != null:
return $default(_that.title,_that.instruction,_that.feedbackCorrect,_that.audio);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String instruction,  String feedbackCorrect,  LessonAudio? audio)  $default,) {final _that = this;
switch (_that) {
case _LessonLocalization():
return $default(_that.title,_that.instruction,_that.feedbackCorrect,_that.audio);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String instruction,  String feedbackCorrect,  LessonAudio? audio)?  $default,) {final _that = this;
switch (_that) {
case _LessonLocalization() when $default != null:
return $default(_that.title,_that.instruction,_that.feedbackCorrect,_that.audio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonLocalization implements LessonLocalization {
  const _LessonLocalization({required this.title, required this.instruction, required this.feedbackCorrect, this.audio});
  factory _LessonLocalization.fromJson(Map<String, dynamic> json) => _$LessonLocalizationFromJson(json);

@override final  String title;
@override final  String instruction;
@override final  String feedbackCorrect;
@override final  LessonAudio? audio;

/// Create a copy of LessonLocalization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonLocalizationCopyWith<_LessonLocalization> get copyWith => __$LessonLocalizationCopyWithImpl<_LessonLocalization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonLocalizationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonLocalization&&(identical(other.title, title) || other.title == title)&&(identical(other.instruction, instruction) || other.instruction == instruction)&&(identical(other.feedbackCorrect, feedbackCorrect) || other.feedbackCorrect == feedbackCorrect)&&(identical(other.audio, audio) || other.audio == audio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,instruction,feedbackCorrect,audio);
}

@override
String toString() {
    return 'LessonLocalization(title: $title, instruction: $instruction, feedbackCorrect: $feedbackCorrect, audio: $audio)';
}


}

/// @nodoc
abstract mixin class _$LessonLocalizationCopyWith<$Res> implements $LessonLocalizationCopyWith<$Res> {
  factory _$LessonLocalizationCopyWith(_LessonLocalization value, $Res Function(_LessonLocalization) _then) = __$LessonLocalizationCopyWithImpl;
@override @useResult
$Res call({
 String title, String instruction, String feedbackCorrect, LessonAudio? audio
});


@override $LessonAudioCopyWith<$Res>? get audio;

}
/// @nodoc
class __$LessonLocalizationCopyWithImpl<$Res>
    implements _$LessonLocalizationCopyWith<$Res> {
  __$LessonLocalizationCopyWithImpl(this._self, this._then);

  final _LessonLocalization _self;
  final $Res Function(_LessonLocalization) _then;

/// Create a copy of LessonLocalization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? instruction = null,Object? feedbackCorrect = null,Object? audio = freezed,}) {
  return _then(_LessonLocalization(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as String,feedbackCorrect: null == feedbackCorrect ? _self.feedbackCorrect : feedbackCorrect // ignore: cast_nullable_to_non_nullable
as String,audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as LessonAudio?,
  ));
}

/// Create a copy of LessonLocalization
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonAudioCopyWith<$Res>? get audio {
    if (_self.audio == null) {
    return null;
  }

  return $LessonAudioCopyWith<$Res>(_self.audio!, (value) {
    return _then(_self.copyWith(audio: value));
  });
}
}


/// @nodoc
mixin _$LessonAudio {

 String? get instructionAssetId;
/// Create a copy of LessonAudio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonAudioCopyWith<LessonAudio> get copyWith => _$LessonAudioCopyWithImpl<LessonAudio>(this as LessonAudio, _$identity);

  /// Serializes this LessonAudio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LessonAudio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonAudio&&(identical(other.instructionAssetId, _this.instructionAssetId) || other.instructionAssetId == _this.instructionAssetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LessonAudio;
  return Object.hash(runtimeType,_this.instructionAssetId);
}

@override
String toString() {
  final _this = this as LessonAudio;
  return 'LessonAudio(instructionAssetId: ${_this.instructionAssetId})';
}


}

/// @nodoc
abstract mixin class $LessonAudioCopyWith<$Res>  {
  factory $LessonAudioCopyWith(LessonAudio value, $Res Function(LessonAudio) _then) = _$LessonAudioCopyWithImpl;
@useResult
$Res call({
 String? instructionAssetId
});




}
/// @nodoc
class _$LessonAudioCopyWithImpl<$Res>
    implements $LessonAudioCopyWith<$Res> {
  _$LessonAudioCopyWithImpl(this._self, this._then);

  final LessonAudio _self;
  final $Res Function(LessonAudio) _then;

/// Create a copy of LessonAudio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instructionAssetId = freezed,}) {
  return _then(LessonAudio(
instructionAssetId: freezed == instructionAssetId ? _self.instructionAssetId : instructionAssetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonAudio].
extension LessonAudioPatterns on LessonAudio {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonAudio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonAudio() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonAudio value)  $default,){
final _that = this;
switch (_that) {
case _LessonAudio():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonAudio value)?  $default,){
final _that = this;
switch (_that) {
case _LessonAudio() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? instructionAssetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonAudio() when $default != null:
return $default(_that.instructionAssetId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? instructionAssetId)  $default,) {final _that = this;
switch (_that) {
case _LessonAudio():
return $default(_that.instructionAssetId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? instructionAssetId)?  $default,) {final _that = this;
switch (_that) {
case _LessonAudio() when $default != null:
return $default(_that.instructionAssetId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonAudio implements LessonAudio {
  const _LessonAudio({this.instructionAssetId});
  factory _LessonAudio.fromJson(Map<String, dynamic> json) => _$LessonAudioFromJson(json);

@override final  String? instructionAssetId;

/// Create a copy of LessonAudio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonAudioCopyWith<_LessonAudio> get copyWith => __$LessonAudioCopyWithImpl<_LessonAudio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonAudioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonAudio&&(identical(other.instructionAssetId, instructionAssetId) || other.instructionAssetId == instructionAssetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,instructionAssetId);
}

@override
String toString() {
    return 'LessonAudio(instructionAssetId: $instructionAssetId)';
}


}

/// @nodoc
abstract mixin class _$LessonAudioCopyWith<$Res> implements $LessonAudioCopyWith<$Res> {
  factory _$LessonAudioCopyWith(_LessonAudio value, $Res Function(_LessonAudio) _then) = __$LessonAudioCopyWithImpl;
@override @useResult
$Res call({
 String? instructionAssetId
});




}
/// @nodoc
class __$LessonAudioCopyWithImpl<$Res>
    implements _$LessonAudioCopyWith<$Res> {
  __$LessonAudioCopyWithImpl(this._self, this._then);

  final _LessonAudio _self;
  final $Res Function(_LessonAudio) _then;

/// Create a copy of LessonAudio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instructionAssetId = freezed,}) {
  return _then(_LessonAudio(
instructionAssetId: freezed == instructionAssetId ? _self.instructionAssetId : instructionAssetId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AssetRef {

 String get assetId; String get mediaType; String get sha256;
/// Create a copy of AssetRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetRefCopyWith<AssetRef> get copyWith => _$AssetRefCopyWithImpl<AssetRef>(this as AssetRef, _$identity);

  /// Serializes this AssetRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AssetRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetRef&&(identical(other.assetId, _this.assetId) || other.assetId == _this.assetId)&&(identical(other.mediaType, _this.mediaType) || other.mediaType == _this.mediaType)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AssetRef;
  return Object.hash(runtimeType,_this.assetId,_this.mediaType,_this.sha256);
}

@override
String toString() {
  final _this = this as AssetRef;
  return 'AssetRef(assetId: ${_this.assetId}, mediaType: ${_this.mediaType}, sha256: ${_this.sha256})';
}


}

/// @nodoc
abstract mixin class $AssetRefCopyWith<$Res>  {
  factory $AssetRefCopyWith(AssetRef value, $Res Function(AssetRef) _then) = _$AssetRefCopyWithImpl;
@useResult
$Res call({
 String assetId, String mediaType, String sha256
});




}
/// @nodoc
class _$AssetRefCopyWithImpl<$Res>
    implements $AssetRefCopyWith<$Res> {
  _$AssetRefCopyWithImpl(this._self, this._then);

  final AssetRef _self;
  final $Res Function(AssetRef) _then;

/// Create a copy of AssetRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetId = null,Object? mediaType = null,Object? sha256 = null,}) {
  return _then(AssetRef(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetRef].
extension AssetRefPatterns on AssetRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetRef value)  $default,){
final _that = this;
switch (_that) {
case _AssetRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetRef value)?  $default,){
final _that = this;
switch (_that) {
case _AssetRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assetId,  String mediaType,  String sha256)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetRef() when $default != null:
return $default(_that.assetId,_that.mediaType,_that.sha256);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assetId,  String mediaType,  String sha256)  $default,) {final _that = this;
switch (_that) {
case _AssetRef():
return $default(_that.assetId,_that.mediaType,_that.sha256);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assetId,  String mediaType,  String sha256)?  $default,) {final _that = this;
switch (_that) {
case _AssetRef() when $default != null:
return $default(_that.assetId,_that.mediaType,_that.sha256);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssetRef implements AssetRef {
  const _AssetRef({required this.assetId, required this.mediaType, required this.sha256});
  factory _AssetRef.fromJson(Map<String, dynamic> json) => _$AssetRefFromJson(json);

@override final  String assetId;
@override final  String mediaType;
@override final  String sha256;

/// Create a copy of AssetRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetRefCopyWith<_AssetRef> get copyWith => __$AssetRefCopyWithImpl<_AssetRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetRef&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,assetId,mediaType,sha256);
}

@override
String toString() {
    return 'AssetRef(assetId: $assetId, mediaType: $mediaType, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class _$AssetRefCopyWith<$Res> implements $AssetRefCopyWith<$Res> {
  factory _$AssetRefCopyWith(_AssetRef value, $Res Function(_AssetRef) _then) = __$AssetRefCopyWithImpl;
@override @useResult
$Res call({
 String assetId, String mediaType, String sha256
});




}
/// @nodoc
class __$AssetRefCopyWithImpl<$Res>
    implements _$AssetRefCopyWith<$Res> {
  __$AssetRefCopyWithImpl(this._self, this._then);

  final _AssetRef _self;
  final $Res Function(_AssetRef) _then;

/// Create a copy of AssetRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetId = null,Object? mediaType = null,Object? sha256 = null,}) {
  return _then(_AssetRef(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TapToLearn {

 String get type; String get targetAssetId; String get completionRule; String get retryPolicy;
/// Create a copy of TapToLearn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TapToLearnCopyWith<TapToLearn> get copyWith => _$TapToLearnCopyWithImpl<TapToLearn>(this as TapToLearn, _$identity);

  /// Serializes this TapToLearn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TapToLearn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TapToLearn&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.targetAssetId, _this.targetAssetId) || other.targetAssetId == _this.targetAssetId)&&(identical(other.completionRule, _this.completionRule) || other.completionRule == _this.completionRule)&&(identical(other.retryPolicy, _this.retryPolicy) || other.retryPolicy == _this.retryPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TapToLearn;
  return Object.hash(runtimeType,_this.type,_this.targetAssetId,_this.completionRule,_this.retryPolicy);
}

@override
String toString() {
  final _this = this as TapToLearn;
  return 'TapToLearn(type: ${_this.type}, targetAssetId: ${_this.targetAssetId}, completionRule: ${_this.completionRule}, retryPolicy: ${_this.retryPolicy})';
}


}

/// @nodoc
abstract mixin class $TapToLearnCopyWith<$Res>  {
  factory $TapToLearnCopyWith(TapToLearn value, $Res Function(TapToLearn) _then) = _$TapToLearnCopyWithImpl;
@useResult
$Res call({
 String type, String targetAssetId, String completionRule, String retryPolicy
});




}
/// @nodoc
class _$TapToLearnCopyWithImpl<$Res>
    implements $TapToLearnCopyWith<$Res> {
  _$TapToLearnCopyWithImpl(this._self, this._then);

  final TapToLearn _self;
  final $Res Function(TapToLearn) _then;

/// Create a copy of TapToLearn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? targetAssetId = null,Object? completionRule = null,Object? retryPolicy = null,}) {
  return _then(TapToLearn(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,targetAssetId: null == targetAssetId ? _self.targetAssetId : targetAssetId // ignore: cast_nullable_to_non_nullable
as String,completionRule: null == completionRule ? _self.completionRule : completionRule // ignore: cast_nullable_to_non_nullable
as String,retryPolicy: null == retryPolicy ? _self.retryPolicy : retryPolicy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TapToLearn].
extension TapToLearnPatterns on TapToLearn {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TapToLearn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TapToLearn() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TapToLearn value)  $default,){
final _that = this;
switch (_that) {
case _TapToLearn():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TapToLearn value)?  $default,){
final _that = this;
switch (_that) {
case _TapToLearn() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String targetAssetId,  String completionRule,  String retryPolicy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TapToLearn() when $default != null:
return $default(_that.type,_that.targetAssetId,_that.completionRule,_that.retryPolicy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String targetAssetId,  String completionRule,  String retryPolicy)  $default,) {final _that = this;
switch (_that) {
case _TapToLearn():
return $default(_that.type,_that.targetAssetId,_that.completionRule,_that.retryPolicy);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String targetAssetId,  String completionRule,  String retryPolicy)?  $default,) {final _that = this;
switch (_that) {
case _TapToLearn() when $default != null:
return $default(_that.type,_that.targetAssetId,_that.completionRule,_that.retryPolicy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TapToLearn implements TapToLearn {
  const _TapToLearn({required this.type, required this.targetAssetId, required this.completionRule, required this.retryPolicy});
  factory _TapToLearn.fromJson(Map<String, dynamic> json) => _$TapToLearnFromJson(json);

@override final  String type;
@override final  String targetAssetId;
@override final  String completionRule;
@override final  String retryPolicy;

/// Create a copy of TapToLearn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TapToLearnCopyWith<_TapToLearn> get copyWith => __$TapToLearnCopyWithImpl<_TapToLearn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TapToLearnToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TapToLearn&&(identical(other.type, type) || other.type == type)&&(identical(other.targetAssetId, targetAssetId) || other.targetAssetId == targetAssetId)&&(identical(other.completionRule, completionRule) || other.completionRule == completionRule)&&(identical(other.retryPolicy, retryPolicy) || other.retryPolicy == retryPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,targetAssetId,completionRule,retryPolicy);
}

@override
String toString() {
    return 'TapToLearn(type: $type, targetAssetId: $targetAssetId, completionRule: $completionRule, retryPolicy: $retryPolicy)';
}


}

/// @nodoc
abstract mixin class _$TapToLearnCopyWith<$Res> implements $TapToLearnCopyWith<$Res> {
  factory _$TapToLearnCopyWith(_TapToLearn value, $Res Function(_TapToLearn) _then) = __$TapToLearnCopyWithImpl;
@override @useResult
$Res call({
 String type, String targetAssetId, String completionRule, String retryPolicy
});




}
/// @nodoc
class __$TapToLearnCopyWithImpl<$Res>
    implements _$TapToLearnCopyWith<$Res> {
  __$TapToLearnCopyWithImpl(this._self, this._then);

  final _TapToLearn _self;
  final $Res Function(_TapToLearn) _then;

/// Create a copy of TapToLearn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? targetAssetId = null,Object? completionRule = null,Object? retryPolicy = null,}) {
  return _then(_TapToLearn(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,targetAssetId: null == targetAssetId ? _self.targetAssetId : targetAssetId // ignore: cast_nullable_to_non_nullable
as String,completionRule: null == completionRule ? _self.completionRule : completionRule // ignore: cast_nullable_to_non_nullable
as String,retryPolicy: null == retryPolicy ? _self.retryPolicy : retryPolicy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LessonAccessibility {

 Map<String, String> get imageLabel; bool get requiresAudio;
/// Create a copy of LessonAccessibility
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonAccessibilityCopyWith<LessonAccessibility> get copyWith => _$LessonAccessibilityCopyWithImpl<LessonAccessibility>(this as LessonAccessibility, _$identity);

  /// Serializes this LessonAccessibility to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LessonAccessibility;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonAccessibility&&const DeepCollectionEquality().equals(other.imageLabel, _this.imageLabel)&&(identical(other.requiresAudio, _this.requiresAudio) || other.requiresAudio == _this.requiresAudio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LessonAccessibility;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.imageLabel),_this.requiresAudio);
}

@override
String toString() {
  final _this = this as LessonAccessibility;
  return 'LessonAccessibility(imageLabel: ${_this.imageLabel}, requiresAudio: ${_this.requiresAudio})';
}


}

/// @nodoc
abstract mixin class $LessonAccessibilityCopyWith<$Res>  {
  factory $LessonAccessibilityCopyWith(LessonAccessibility value, $Res Function(LessonAccessibility) _then) = _$LessonAccessibilityCopyWithImpl;
@useResult
$Res call({
 Map<String, String> imageLabel, bool requiresAudio
});




}
/// @nodoc
class _$LessonAccessibilityCopyWithImpl<$Res>
    implements $LessonAccessibilityCopyWith<$Res> {
  _$LessonAccessibilityCopyWithImpl(this._self, this._then);

  final LessonAccessibility _self;
  final $Res Function(LessonAccessibility) _then;

/// Create a copy of LessonAccessibility
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? imageLabel = null,Object? requiresAudio = null,}) {
  return _then(LessonAccessibility(
imageLabel: null == imageLabel ? _self.imageLabel : imageLabel // ignore: cast_nullable_to_non_nullable
as Map<String, String>,requiresAudio: null == requiresAudio ? _self.requiresAudio : requiresAudio // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonAccessibility].
extension LessonAccessibilityPatterns on LessonAccessibility {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonAccessibility value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonAccessibility() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonAccessibility value)  $default,){
final _that = this;
switch (_that) {
case _LessonAccessibility():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonAccessibility value)?  $default,){
final _that = this;
switch (_that) {
case _LessonAccessibility() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String> imageLabel,  bool requiresAudio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonAccessibility() when $default != null:
return $default(_that.imageLabel,_that.requiresAudio);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String> imageLabel,  bool requiresAudio)  $default,) {final _that = this;
switch (_that) {
case _LessonAccessibility():
return $default(_that.imageLabel,_that.requiresAudio);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String> imageLabel,  bool requiresAudio)?  $default,) {final _that = this;
switch (_that) {
case _LessonAccessibility() when $default != null:
return $default(_that.imageLabel,_that.requiresAudio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonAccessibility implements LessonAccessibility {
  const _LessonAccessibility({required  Map<String, String> imageLabel, required this.requiresAudio}): _imageLabel = imageLabel;
  factory _LessonAccessibility.fromJson(Map<String, dynamic> json) => _$LessonAccessibilityFromJson(json);

 final  Map<String, String> _imageLabel;
@override Map<String, String> get imageLabel {
  if (_imageLabel is EqualUnmodifiableMapView) return _imageLabel;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_imageLabel);
}

@override final  bool requiresAudio;

/// Create a copy of LessonAccessibility
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonAccessibilityCopyWith<_LessonAccessibility> get copyWith => __$LessonAccessibilityCopyWithImpl<_LessonAccessibility>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonAccessibilityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonAccessibility&&const DeepCollectionEquality().equals(other.imageLabel, _imageLabel)&&(identical(other.requiresAudio, requiresAudio) || other.requiresAudio == requiresAudio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_imageLabel),requiresAudio);
}

@override
String toString() {
    return 'LessonAccessibility(imageLabel: $imageLabel, requiresAudio: $requiresAudio)';
}


}

/// @nodoc
abstract mixin class _$LessonAccessibilityCopyWith<$Res> implements $LessonAccessibilityCopyWith<$Res> {
  factory _$LessonAccessibilityCopyWith(_LessonAccessibility value, $Res Function(_LessonAccessibility) _then) = __$LessonAccessibilityCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String> imageLabel, bool requiresAudio
});




}
/// @nodoc
class __$LessonAccessibilityCopyWithImpl<$Res>
    implements _$LessonAccessibilityCopyWith<$Res> {
  __$LessonAccessibilityCopyWithImpl(this._self, this._then);

  final _LessonAccessibility _self;
  final $Res Function(_LessonAccessibility) _then;

/// Create a copy of LessonAccessibility
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? imageLabel = null,Object? requiresAudio = null,}) {
  return _then(_LessonAccessibility(
imageLabel: null == imageLabel ? _self._imageLabel : imageLabel // ignore: cast_nullable_to_non_nullable
as Map<String, String>,requiresAudio: null == requiresAudio ? _self.requiresAudio : requiresAudio // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
