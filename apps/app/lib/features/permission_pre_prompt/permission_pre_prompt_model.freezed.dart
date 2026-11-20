// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permission_pre_prompt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PermissionPrePromptModel {

 PermissionKind get kind;
/// Create a copy of PermissionPrePromptModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionPrePromptModelCopyWith<PermissionPrePromptModel> get copyWith => _$PermissionPrePromptModelCopyWithImpl<PermissionPrePromptModel>(this as PermissionPrePromptModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionPrePromptModel&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'PermissionPrePromptModel(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $PermissionPrePromptModelCopyWith<$Res>  {
  factory $PermissionPrePromptModelCopyWith(PermissionPrePromptModel value, $Res Function(PermissionPrePromptModel) _then) = _$PermissionPrePromptModelCopyWithImpl;
@useResult
$Res call({
 PermissionKind kind
});




}
/// @nodoc
class _$PermissionPrePromptModelCopyWithImpl<$Res>
    implements $PermissionPrePromptModelCopyWith<$Res> {
  _$PermissionPrePromptModelCopyWithImpl(this._self, this._then);

  final PermissionPrePromptModel _self;
  final $Res Function(PermissionPrePromptModel) _then;

/// Create a copy of PermissionPrePromptModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PermissionKind,
  ));
}

}


/// Adds pattern-matching-related methods to [PermissionPrePromptModel].
extension PermissionPrePromptModelPatterns on PermissionPrePromptModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PermissionPrePromptModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PermissionPrePromptModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PermissionPrePromptModel value)  $default,){
final _that = this;
switch (_that) {
case _PermissionPrePromptModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PermissionPrePromptModel value)?  $default,){
final _that = this;
switch (_that) {
case _PermissionPrePromptModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PermissionKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PermissionPrePromptModel() when $default != null:
return $default(_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PermissionKind kind)  $default,) {final _that = this;
switch (_that) {
case _PermissionPrePromptModel():
return $default(_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PermissionKind kind)?  $default,) {final _that = this;
switch (_that) {
case _PermissionPrePromptModel() when $default != null:
return $default(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _PermissionPrePromptModel implements PermissionPrePromptModel {
  const _PermissionPrePromptModel({required this.kind});
  

@override final  PermissionKind kind;

/// Create a copy of PermissionPrePromptModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionPrePromptModelCopyWith<_PermissionPrePromptModel> get copyWith => __$PermissionPrePromptModelCopyWithImpl<_PermissionPrePromptModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionPrePromptModel&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'PermissionPrePromptModel(kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$PermissionPrePromptModelCopyWith<$Res> implements $PermissionPrePromptModelCopyWith<$Res> {
  factory _$PermissionPrePromptModelCopyWith(_PermissionPrePromptModel value, $Res Function(_PermissionPrePromptModel) _then) = __$PermissionPrePromptModelCopyWithImpl;
@override @useResult
$Res call({
 PermissionKind kind
});




}
/// @nodoc
class __$PermissionPrePromptModelCopyWithImpl<$Res>
    implements _$PermissionPrePromptModelCopyWith<$Res> {
  __$PermissionPrePromptModelCopyWithImpl(this._self, this._then);

  final _PermissionPrePromptModel _self;
  final $Res Function(_PermissionPrePromptModel) _then;

/// Create a copy of PermissionPrePromptModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(_PermissionPrePromptModel(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PermissionKind,
  ));
}


}

// dart format on
