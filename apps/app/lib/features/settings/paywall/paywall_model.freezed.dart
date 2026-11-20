// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paywall_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaywallModel {

/// The owner's entitlement, or null until it has loaded (or when nobody
/// is signed in).
 Entitlement? get entitlement;/// The quantity to subscribe to, or to change to (units: monitored
/// sites, seats, ...).
 int get quantity;/// Whether the entitlement is still loading.
 bool get loading;/// Whether a checkout, portal or quantity call is running.
 bool get busy;/// Whether the last call failed.
 bool get failed;/// Whether nobody is signed in, so there is nobody to bill.
 bool get signedOut;
/// Create a copy of PaywallModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaywallModelCopyWith<PaywallModel> get copyWith => _$PaywallModelCopyWithImpl<PaywallModel>(this as PaywallModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallModel&&(identical(other.entitlement, entitlement) || other.entitlement == entitlement)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.signedOut, signedOut) || other.signedOut == signedOut));
}


@override
int get hashCode => Object.hash(runtimeType,entitlement,quantity,loading,busy,failed,signedOut);

@override
String toString() {
  return 'PaywallModel(entitlement: $entitlement, quantity: $quantity, loading: $loading, busy: $busy, failed: $failed, signedOut: $signedOut)';
}


}

/// @nodoc
abstract mixin class $PaywallModelCopyWith<$Res>  {
  factory $PaywallModelCopyWith(PaywallModel value, $Res Function(PaywallModel) _then) = _$PaywallModelCopyWithImpl;
@useResult
$Res call({
 Entitlement? entitlement, int quantity, bool loading, bool busy, bool failed, bool signedOut
});




}
/// @nodoc
class _$PaywallModelCopyWithImpl<$Res>
    implements $PaywallModelCopyWith<$Res> {
  _$PaywallModelCopyWithImpl(this._self, this._then);

  final PaywallModel _self;
  final $Res Function(PaywallModel) _then;

/// Create a copy of PaywallModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entitlement = freezed,Object? quantity = null,Object? loading = null,Object? busy = null,Object? failed = null,Object? signedOut = null,}) {
  return _then(_self.copyWith(
entitlement: freezed == entitlement ? _self.entitlement : entitlement // ignore: cast_nullable_to_non_nullable
as Entitlement?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,signedOut: null == signedOut ? _self.signedOut : signedOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaywallModel].
extension PaywallModelPatterns on PaywallModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaywallModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaywallModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaywallModel value)  $default,){
final _that = this;
switch (_that) {
case _PaywallModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaywallModel value)?  $default,){
final _that = this;
switch (_that) {
case _PaywallModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Entitlement? entitlement,  int quantity,  bool loading,  bool busy,  bool failed,  bool signedOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaywallModel() when $default != null:
return $default(_that.entitlement,_that.quantity,_that.loading,_that.busy,_that.failed,_that.signedOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Entitlement? entitlement,  int quantity,  bool loading,  bool busy,  bool failed,  bool signedOut)  $default,) {final _that = this;
switch (_that) {
case _PaywallModel():
return $default(_that.entitlement,_that.quantity,_that.loading,_that.busy,_that.failed,_that.signedOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Entitlement? entitlement,  int quantity,  bool loading,  bool busy,  bool failed,  bool signedOut)?  $default,) {final _that = this;
switch (_that) {
case _PaywallModel() when $default != null:
return $default(_that.entitlement,_that.quantity,_that.loading,_that.busy,_that.failed,_that.signedOut);case _:
  return null;

}
}

}

/// @nodoc


class _PaywallModel implements PaywallModel {
  const _PaywallModel({this.entitlement, this.quantity = 1, this.loading = true, this.busy = false, this.failed = false, this.signedOut = false});
  

/// The owner's entitlement, or null until it has loaded (or when nobody
/// is signed in).
@override final  Entitlement? entitlement;
/// The quantity to subscribe to, or to change to (units: monitored
/// sites, seats, ...).
@override@JsonKey() final  int quantity;
/// Whether the entitlement is still loading.
@override@JsonKey() final  bool loading;
/// Whether a checkout, portal or quantity call is running.
@override@JsonKey() final  bool busy;
/// Whether the last call failed.
@override@JsonKey() final  bool failed;
/// Whether nobody is signed in, so there is nobody to bill.
@override@JsonKey() final  bool signedOut;

/// Create a copy of PaywallModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaywallModelCopyWith<_PaywallModel> get copyWith => __$PaywallModelCopyWithImpl<_PaywallModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaywallModel&&(identical(other.entitlement, entitlement) || other.entitlement == entitlement)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.signedOut, signedOut) || other.signedOut == signedOut));
}


@override
int get hashCode => Object.hash(runtimeType,entitlement,quantity,loading,busy,failed,signedOut);

@override
String toString() {
  return 'PaywallModel(entitlement: $entitlement, quantity: $quantity, loading: $loading, busy: $busy, failed: $failed, signedOut: $signedOut)';
}


}

/// @nodoc
abstract mixin class _$PaywallModelCopyWith<$Res> implements $PaywallModelCopyWith<$Res> {
  factory _$PaywallModelCopyWith(_PaywallModel value, $Res Function(_PaywallModel) _then) = __$PaywallModelCopyWithImpl;
@override @useResult
$Res call({
 Entitlement? entitlement, int quantity, bool loading, bool busy, bool failed, bool signedOut
});




}
/// @nodoc
class __$PaywallModelCopyWithImpl<$Res>
    implements _$PaywallModelCopyWith<$Res> {
  __$PaywallModelCopyWithImpl(this._self, this._then);

  final _PaywallModel _self;
  final $Res Function(_PaywallModel) _then;

/// Create a copy of PaywallModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entitlement = freezed,Object? quantity = null,Object? loading = null,Object? busy = null,Object? failed = null,Object? signedOut = null,}) {
  return _then(_PaywallModel(
entitlement: freezed == entitlement ? _self.entitlement : entitlement // ignore: cast_nullable_to_non_nullable
as Entitlement?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,signedOut: null == signedOut ? _self.signedOut : signedOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
