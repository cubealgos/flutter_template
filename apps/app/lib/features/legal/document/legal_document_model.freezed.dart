// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_document_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LegalDocumentModel {

 LegalDocumentType get type;
/// Create a copy of LegalDocumentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalDocumentModelCopyWith<LegalDocumentModel> get copyWith => _$LegalDocumentModelCopyWithImpl<LegalDocumentModel>(this as LegalDocumentModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalDocumentModel&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'LegalDocumentModel(type: $type)';
}


}

/// @nodoc
abstract mixin class $LegalDocumentModelCopyWith<$Res>  {
  factory $LegalDocumentModelCopyWith(LegalDocumentModel value, $Res Function(LegalDocumentModel) _then) = _$LegalDocumentModelCopyWithImpl;
@useResult
$Res call({
 LegalDocumentType type
});




}
/// @nodoc
class _$LegalDocumentModelCopyWithImpl<$Res>
    implements $LegalDocumentModelCopyWith<$Res> {
  _$LegalDocumentModelCopyWithImpl(this._self, this._then);

  final LegalDocumentModel _self;
  final $Res Function(LegalDocumentModel) _then;

/// Create a copy of LegalDocumentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LegalDocumentType,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalDocumentModel].
extension LegalDocumentModelPatterns on LegalDocumentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalDocumentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalDocumentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalDocumentModel value)  $default,){
final _that = this;
switch (_that) {
case _LegalDocumentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalDocumentModel value)?  $default,){
final _that = this;
switch (_that) {
case _LegalDocumentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LegalDocumentType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalDocumentModel() when $default != null:
return $default(_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LegalDocumentType type)  $default,) {final _that = this;
switch (_that) {
case _LegalDocumentModel():
return $default(_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LegalDocumentType type)?  $default,) {final _that = this;
switch (_that) {
case _LegalDocumentModel() when $default != null:
return $default(_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _LegalDocumentModel implements LegalDocumentModel {
  const _LegalDocumentModel({required this.type});
  

@override final  LegalDocumentType type;

/// Create a copy of LegalDocumentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalDocumentModelCopyWith<_LegalDocumentModel> get copyWith => __$LegalDocumentModelCopyWithImpl<_LegalDocumentModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalDocumentModel&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'LegalDocumentModel(type: $type)';
}


}

/// @nodoc
abstract mixin class _$LegalDocumentModelCopyWith<$Res> implements $LegalDocumentModelCopyWith<$Res> {
  factory _$LegalDocumentModelCopyWith(_LegalDocumentModel value, $Res Function(_LegalDocumentModel) _then) = __$LegalDocumentModelCopyWithImpl;
@override @useResult
$Res call({
 LegalDocumentType type
});




}
/// @nodoc
class __$LegalDocumentModelCopyWithImpl<$Res>
    implements _$LegalDocumentModelCopyWith<$Res> {
  __$LegalDocumentModelCopyWithImpl(this._self, this._then);

  final _LegalDocumentModel _self;
  final $Res Function(_LegalDocumentModel) _then;

/// Create a copy of LegalDocumentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_LegalDocumentModel(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LegalDocumentType,
  ));
}


}

// dart format on
