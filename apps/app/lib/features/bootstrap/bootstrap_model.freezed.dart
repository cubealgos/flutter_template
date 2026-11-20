// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bootstrap_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BootstrapModel {

 BootstrapStatus get status; Uri? get updateUrl; String? get updateMessage;
/// Create a copy of BootstrapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BootstrapModelCopyWith<BootstrapModel> get copyWith => _$BootstrapModelCopyWithImpl<BootstrapModel>(this as BootstrapModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BootstrapModel&&(identical(other.status, status) || other.status == status)&&(identical(other.updateUrl, updateUrl) || other.updateUrl == updateUrl)&&(identical(other.updateMessage, updateMessage) || other.updateMessage == updateMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,updateUrl,updateMessage);

@override
String toString() {
  return 'BootstrapModel(status: $status, updateUrl: $updateUrl, updateMessage: $updateMessage)';
}


}

/// @nodoc
abstract mixin class $BootstrapModelCopyWith<$Res>  {
  factory $BootstrapModelCopyWith(BootstrapModel value, $Res Function(BootstrapModel) _then) = _$BootstrapModelCopyWithImpl;
@useResult
$Res call({
 BootstrapStatus status, Uri? updateUrl, String? updateMessage
});




}
/// @nodoc
class _$BootstrapModelCopyWithImpl<$Res>
    implements $BootstrapModelCopyWith<$Res> {
  _$BootstrapModelCopyWithImpl(this._self, this._then);

  final BootstrapModel _self;
  final $Res Function(BootstrapModel) _then;

/// Create a copy of BootstrapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? updateUrl = freezed,Object? updateMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BootstrapStatus,updateUrl: freezed == updateUrl ? _self.updateUrl : updateUrl // ignore: cast_nullable_to_non_nullable
as Uri?,updateMessage: freezed == updateMessage ? _self.updateMessage : updateMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BootstrapModel].
extension BootstrapModelPatterns on BootstrapModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BootstrapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BootstrapModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BootstrapModel value)  $default,){
final _that = this;
switch (_that) {
case _BootstrapModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BootstrapModel value)?  $default,){
final _that = this;
switch (_that) {
case _BootstrapModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BootstrapStatus status,  Uri? updateUrl,  String? updateMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BootstrapModel() when $default != null:
return $default(_that.status,_that.updateUrl,_that.updateMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BootstrapStatus status,  Uri? updateUrl,  String? updateMessage)  $default,) {final _that = this;
switch (_that) {
case _BootstrapModel():
return $default(_that.status,_that.updateUrl,_that.updateMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BootstrapStatus status,  Uri? updateUrl,  String? updateMessage)?  $default,) {final _that = this;
switch (_that) {
case _BootstrapModel() when $default != null:
return $default(_that.status,_that.updateUrl,_that.updateMessage);case _:
  return null;

}
}

}

/// @nodoc


class _BootstrapModel implements BootstrapModel {
  const _BootstrapModel({this.status = BootstrapStatus.checking, this.updateUrl, this.updateMessage});
  

@override@JsonKey() final  BootstrapStatus status;
@override final  Uri? updateUrl;
@override final  String? updateMessage;

/// Create a copy of BootstrapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BootstrapModelCopyWith<_BootstrapModel> get copyWith => __$BootstrapModelCopyWithImpl<_BootstrapModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BootstrapModel&&(identical(other.status, status) || other.status == status)&&(identical(other.updateUrl, updateUrl) || other.updateUrl == updateUrl)&&(identical(other.updateMessage, updateMessage) || other.updateMessage == updateMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,updateUrl,updateMessage);

@override
String toString() {
  return 'BootstrapModel(status: $status, updateUrl: $updateUrl, updateMessage: $updateMessage)';
}


}

/// @nodoc
abstract mixin class _$BootstrapModelCopyWith<$Res> implements $BootstrapModelCopyWith<$Res> {
  factory _$BootstrapModelCopyWith(_BootstrapModel value, $Res Function(_BootstrapModel) _then) = __$BootstrapModelCopyWithImpl;
@override @useResult
$Res call({
 BootstrapStatus status, Uri? updateUrl, String? updateMessage
});




}
/// @nodoc
class __$BootstrapModelCopyWithImpl<$Res>
    implements _$BootstrapModelCopyWith<$Res> {
  __$BootstrapModelCopyWithImpl(this._self, this._then);

  final _BootstrapModel _self;
  final $Res Function(_BootstrapModel) _then;

/// Create a copy of BootstrapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? updateUrl = freezed,Object? updateMessage = freezed,}) {
  return _then(_BootstrapModel(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BootstrapStatus,updateUrl: freezed == updateUrl ? _self.updateUrl : updateUrl // ignore: cast_nullable_to_non_nullable
as Uri?,updateMessage: freezed == updateMessage ? _self.updateMessage : updateMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
