// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'privacy_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PrivacySettingsModel {

 ConsentStatus get consentStatus; ExportPhase get exportPhase;/// The export flow's typed failure, if any — see [ExportError].
 ExportError? get exportError;/// The exported data as JSON, once [exportPhase] is
/// [ExportPhase.result].
 String? get exportedJson;
/// Create a copy of PrivacySettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacySettingsModelCopyWith<PrivacySettingsModel> get copyWith => _$PrivacySettingsModelCopyWithImpl<PrivacySettingsModel>(this as PrivacySettingsModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacySettingsModel&&(identical(other.consentStatus, consentStatus) || other.consentStatus == consentStatus)&&(identical(other.exportPhase, exportPhase) || other.exportPhase == exportPhase)&&(identical(other.exportError, exportError) || other.exportError == exportError)&&(identical(other.exportedJson, exportedJson) || other.exportedJson == exportedJson));
}


@override
int get hashCode => Object.hash(runtimeType,consentStatus,exportPhase,exportError,exportedJson);

@override
String toString() {
  return 'PrivacySettingsModel(consentStatus: $consentStatus, exportPhase: $exportPhase, exportError: $exportError, exportedJson: $exportedJson)';
}


}

/// @nodoc
abstract mixin class $PrivacySettingsModelCopyWith<$Res>  {
  factory $PrivacySettingsModelCopyWith(PrivacySettingsModel value, $Res Function(PrivacySettingsModel) _then) = _$PrivacySettingsModelCopyWithImpl;
@useResult
$Res call({
 ConsentStatus consentStatus, ExportPhase exportPhase, ExportError? exportError, String? exportedJson
});




}
/// @nodoc
class _$PrivacySettingsModelCopyWithImpl<$Res>
    implements $PrivacySettingsModelCopyWith<$Res> {
  _$PrivacySettingsModelCopyWithImpl(this._self, this._then);

  final PrivacySettingsModel _self;
  final $Res Function(PrivacySettingsModel) _then;

/// Create a copy of PrivacySettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? consentStatus = null,Object? exportPhase = null,Object? exportError = freezed,Object? exportedJson = freezed,}) {
  return _then(_self.copyWith(
consentStatus: null == consentStatus ? _self.consentStatus : consentStatus // ignore: cast_nullable_to_non_nullable
as ConsentStatus,exportPhase: null == exportPhase ? _self.exportPhase : exportPhase // ignore: cast_nullable_to_non_nullable
as ExportPhase,exportError: freezed == exportError ? _self.exportError : exportError // ignore: cast_nullable_to_non_nullable
as ExportError?,exportedJson: freezed == exportedJson ? _self.exportedJson : exportedJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivacySettingsModel].
extension PrivacySettingsModelPatterns on PrivacySettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivacySettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivacySettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivacySettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _PrivacySettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivacySettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PrivacySettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConsentStatus consentStatus,  ExportPhase exportPhase,  ExportError? exportError,  String? exportedJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivacySettingsModel() when $default != null:
return $default(_that.consentStatus,_that.exportPhase,_that.exportError,_that.exportedJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConsentStatus consentStatus,  ExportPhase exportPhase,  ExportError? exportError,  String? exportedJson)  $default,) {final _that = this;
switch (_that) {
case _PrivacySettingsModel():
return $default(_that.consentStatus,_that.exportPhase,_that.exportError,_that.exportedJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConsentStatus consentStatus,  ExportPhase exportPhase,  ExportError? exportError,  String? exportedJson)?  $default,) {final _that = this;
switch (_that) {
case _PrivacySettingsModel() when $default != null:
return $default(_that.consentStatus,_that.exportPhase,_that.exportError,_that.exportedJson);case _:
  return null;

}
}

}

/// @nodoc


class _PrivacySettingsModel implements PrivacySettingsModel {
  const _PrivacySettingsModel({this.consentStatus = ConsentStatus.notSet, this.exportPhase = ExportPhase.idle, this.exportError, this.exportedJson});
  

@override@JsonKey() final  ConsentStatus consentStatus;
@override@JsonKey() final  ExportPhase exportPhase;
/// The export flow's typed failure, if any — see [ExportError].
@override final  ExportError? exportError;
/// The exported data as JSON, once [exportPhase] is
/// [ExportPhase.result].
@override final  String? exportedJson;

/// Create a copy of PrivacySettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivacySettingsModelCopyWith<_PrivacySettingsModel> get copyWith => __$PrivacySettingsModelCopyWithImpl<_PrivacySettingsModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivacySettingsModel&&(identical(other.consentStatus, consentStatus) || other.consentStatus == consentStatus)&&(identical(other.exportPhase, exportPhase) || other.exportPhase == exportPhase)&&(identical(other.exportError, exportError) || other.exportError == exportError)&&(identical(other.exportedJson, exportedJson) || other.exportedJson == exportedJson));
}


@override
int get hashCode => Object.hash(runtimeType,consentStatus,exportPhase,exportError,exportedJson);

@override
String toString() {
  return 'PrivacySettingsModel(consentStatus: $consentStatus, exportPhase: $exportPhase, exportError: $exportError, exportedJson: $exportedJson)';
}


}

/// @nodoc
abstract mixin class _$PrivacySettingsModelCopyWith<$Res> implements $PrivacySettingsModelCopyWith<$Res> {
  factory _$PrivacySettingsModelCopyWith(_PrivacySettingsModel value, $Res Function(_PrivacySettingsModel) _then) = __$PrivacySettingsModelCopyWithImpl;
@override @useResult
$Res call({
 ConsentStatus consentStatus, ExportPhase exportPhase, ExportError? exportError, String? exportedJson
});




}
/// @nodoc
class __$PrivacySettingsModelCopyWithImpl<$Res>
    implements _$PrivacySettingsModelCopyWith<$Res> {
  __$PrivacySettingsModelCopyWithImpl(this._self, this._then);

  final _PrivacySettingsModel _self;
  final $Res Function(_PrivacySettingsModel) _then;

/// Create a copy of PrivacySettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? consentStatus = null,Object? exportPhase = null,Object? exportError = freezed,Object? exportedJson = freezed,}) {
  return _then(_PrivacySettingsModel(
consentStatus: null == consentStatus ? _self.consentStatus : consentStatus // ignore: cast_nullable_to_non_nullable
as ConsentStatus,exportPhase: null == exportPhase ? _self.exportPhase : exportPhase // ignore: cast_nullable_to_non_nullable
as ExportPhase,exportError: freezed == exportError ? _self.exportError : exportError // ignore: cast_nullable_to_non_nullable
as ExportError?,exportedJson: freezed == exportedJson ? _self.exportedJson : exportedJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
