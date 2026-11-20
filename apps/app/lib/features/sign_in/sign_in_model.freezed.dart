// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_in_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignInModel {

 SignInStep get step; bool get submitting; SignInError? get error;/// Seconds left before "Resend code" is tappable again — `0` means it
/// is available now. Set by `SignInController` after a code is sent
/// (initial request or resend), spec.md §2.3's ~30-60s resend cooldown.
 int get secondsRemaining;
/// Create a copy of SignInModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignInModelCopyWith<SignInModel> get copyWith => _$SignInModelCopyWithImpl<SignInModel>(this as SignInModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInModel&&(identical(other.step, step) || other.step == step)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.error, error) || other.error == error)&&(identical(other.secondsRemaining, secondsRemaining) || other.secondsRemaining == secondsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,step,submitting,error,secondsRemaining);

@override
String toString() {
  return 'SignInModel(step: $step, submitting: $submitting, error: $error, secondsRemaining: $secondsRemaining)';
}


}

/// @nodoc
abstract mixin class $SignInModelCopyWith<$Res>  {
  factory $SignInModelCopyWith(SignInModel value, $Res Function(SignInModel) _then) = _$SignInModelCopyWithImpl;
@useResult
$Res call({
 SignInStep step, bool submitting, SignInError? error, int secondsRemaining
});




}
/// @nodoc
class _$SignInModelCopyWithImpl<$Res>
    implements $SignInModelCopyWith<$Res> {
  _$SignInModelCopyWithImpl(this._self, this._then);

  final SignInModel _self;
  final $Res Function(SignInModel) _then;

/// Create a copy of SignInModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? submitting = null,Object? error = freezed,Object? secondsRemaining = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as SignInStep,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as SignInError?,secondsRemaining: null == secondsRemaining ? _self.secondsRemaining : secondsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SignInModel].
extension SignInModelPatterns on SignInModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignInModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignInModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignInModel value)  $default,){
final _that = this;
switch (_that) {
case _SignInModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignInModel value)?  $default,){
final _that = this;
switch (_that) {
case _SignInModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SignInStep step,  bool submitting,  SignInError? error,  int secondsRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignInModel() when $default != null:
return $default(_that.step,_that.submitting,_that.error,_that.secondsRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SignInStep step,  bool submitting,  SignInError? error,  int secondsRemaining)  $default,) {final _that = this;
switch (_that) {
case _SignInModel():
return $default(_that.step,_that.submitting,_that.error,_that.secondsRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SignInStep step,  bool submitting,  SignInError? error,  int secondsRemaining)?  $default,) {final _that = this;
switch (_that) {
case _SignInModel() when $default != null:
return $default(_that.step,_that.submitting,_that.error,_that.secondsRemaining);case _:
  return null;

}
}

}

/// @nodoc


class _SignInModel implements SignInModel {
  const _SignInModel({this.step = SignInStep.emailEntry, this.submitting = false, this.error, this.secondsRemaining = 0});
  

@override@JsonKey() final  SignInStep step;
@override@JsonKey() final  bool submitting;
@override final  SignInError? error;
/// Seconds left before "Resend code" is tappable again — `0` means it
/// is available now. Set by `SignInController` after a code is sent
/// (initial request or resend), spec.md §2.3's ~30-60s resend cooldown.
@override@JsonKey() final  int secondsRemaining;

/// Create a copy of SignInModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignInModelCopyWith<_SignInModel> get copyWith => __$SignInModelCopyWithImpl<_SignInModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInModel&&(identical(other.step, step) || other.step == step)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.error, error) || other.error == error)&&(identical(other.secondsRemaining, secondsRemaining) || other.secondsRemaining == secondsRemaining));
}


@override
int get hashCode => Object.hash(runtimeType,step,submitting,error,secondsRemaining);

@override
String toString() {
  return 'SignInModel(step: $step, submitting: $submitting, error: $error, secondsRemaining: $secondsRemaining)';
}


}

/// @nodoc
abstract mixin class _$SignInModelCopyWith<$Res> implements $SignInModelCopyWith<$Res> {
  factory _$SignInModelCopyWith(_SignInModel value, $Res Function(_SignInModel) _then) = __$SignInModelCopyWithImpl;
@override @useResult
$Res call({
 SignInStep step, bool submitting, SignInError? error, int secondsRemaining
});




}
/// @nodoc
class __$SignInModelCopyWithImpl<$Res>
    implements _$SignInModelCopyWith<$Res> {
  __$SignInModelCopyWithImpl(this._self, this._then);

  final _SignInModel _self;
  final $Res Function(_SignInModel) _then;

/// Create a copy of SignInModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? submitting = null,Object? error = freezed,Object? secondsRemaining = null,}) {
  return _then(_SignInModel(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as SignInStep,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as SignInError?,secondsRemaining: null == secondsRemaining ? _self.secondsRemaining : secondsRemaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
