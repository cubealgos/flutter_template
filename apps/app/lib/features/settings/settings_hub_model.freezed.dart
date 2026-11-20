// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_hub_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsHubModel {

 bool get showPaywall;
/// Create a copy of SettingsHubModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsHubModelCopyWith<SettingsHubModel> get copyWith => _$SettingsHubModelCopyWithImpl<SettingsHubModel>(this as SettingsHubModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsHubModel&&(identical(other.showPaywall, showPaywall) || other.showPaywall == showPaywall));
}


@override
int get hashCode => Object.hash(runtimeType,showPaywall);

@override
String toString() {
  return 'SettingsHubModel(showPaywall: $showPaywall)';
}


}

/// @nodoc
abstract mixin class $SettingsHubModelCopyWith<$Res>  {
  factory $SettingsHubModelCopyWith(SettingsHubModel value, $Res Function(SettingsHubModel) _then) = _$SettingsHubModelCopyWithImpl;
@useResult
$Res call({
 bool showPaywall
});




}
/// @nodoc
class _$SettingsHubModelCopyWithImpl<$Res>
    implements $SettingsHubModelCopyWith<$Res> {
  _$SettingsHubModelCopyWithImpl(this._self, this._then);

  final SettingsHubModel _self;
  final $Res Function(SettingsHubModel) _then;

/// Create a copy of SettingsHubModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showPaywall = null,}) {
  return _then(_self.copyWith(
showPaywall: null == showPaywall ? _self.showPaywall : showPaywall // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsHubModel].
extension SettingsHubModelPatterns on SettingsHubModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsHubModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsHubModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsHubModel value)  $default,){
final _that = this;
switch (_that) {
case _SettingsHubModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsHubModel value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsHubModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool showPaywall)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsHubModel() when $default != null:
return $default(_that.showPaywall);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool showPaywall)  $default,) {final _that = this;
switch (_that) {
case _SettingsHubModel():
return $default(_that.showPaywall);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool showPaywall)?  $default,) {final _that = this;
switch (_that) {
case _SettingsHubModel() when $default != null:
return $default(_that.showPaywall);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsHubModel implements SettingsHubModel {
  const _SettingsHubModel({required this.showPaywall});
  

@override final  bool showPaywall;

/// Create a copy of SettingsHubModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsHubModelCopyWith<_SettingsHubModel> get copyWith => __$SettingsHubModelCopyWithImpl<_SettingsHubModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsHubModel&&(identical(other.showPaywall, showPaywall) || other.showPaywall == showPaywall));
}


@override
int get hashCode => Object.hash(runtimeType,showPaywall);

@override
String toString() {
  return 'SettingsHubModel(showPaywall: $showPaywall)';
}


}

/// @nodoc
abstract mixin class _$SettingsHubModelCopyWith<$Res> implements $SettingsHubModelCopyWith<$Res> {
  factory _$SettingsHubModelCopyWith(_SettingsHubModel value, $Res Function(_SettingsHubModel) _then) = __$SettingsHubModelCopyWithImpl;
@override @useResult
$Res call({
 bool showPaywall
});




}
/// @nodoc
class __$SettingsHubModelCopyWithImpl<$Res>
    implements _$SettingsHubModelCopyWith<$Res> {
  __$SettingsHubModelCopyWithImpl(this._self, this._then);

  final _SettingsHubModel _self;
  final $Res Function(_SettingsHubModel) _then;

/// Create a copy of SettingsHubModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showPaywall = null,}) {
  return _then(_SettingsHubModel(
showPaywall: null == showPaywall ? _self.showPaywall : showPaywall // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
