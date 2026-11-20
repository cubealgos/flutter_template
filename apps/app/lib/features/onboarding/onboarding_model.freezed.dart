// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingModel {

/// The index, into `OnboardingController.steps`, of the step currently
/// shown.
 int get currentStepIndex;/// Whether the initial resume-from-persistence read is still in
/// flight — `true` only for the brief window between construction and
/// `OnboardingController.init` finishing.
 bool get resuming;/// Every step's persisted status so far, keyed by `OnboardingStep.id`.
/// A step with no entry has neither been completed nor skipped.
 Map<String, OnboardingStepStatus> get stepStatus;/// Every step's persisted answer so far, keyed by `OnboardingStep.id`.
 Map<String, dynamic> get answers;
/// Create a copy of OnboardingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingModelCopyWith<OnboardingModel> get copyWith => _$OnboardingModelCopyWithImpl<OnboardingModel>(this as OnboardingModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingModel&&(identical(other.currentStepIndex, currentStepIndex) || other.currentStepIndex == currentStepIndex)&&(identical(other.resuming, resuming) || other.resuming == resuming)&&const DeepCollectionEquality().equals(other.stepStatus, stepStatus)&&const DeepCollectionEquality().equals(other.answers, answers));
}


@override
int get hashCode => Object.hash(runtimeType,currentStepIndex,resuming,const DeepCollectionEquality().hash(stepStatus),const DeepCollectionEquality().hash(answers));

@override
String toString() {
  return 'OnboardingModel(currentStepIndex: $currentStepIndex, resuming: $resuming, stepStatus: $stepStatus, answers: $answers)';
}


}

/// @nodoc
abstract mixin class $OnboardingModelCopyWith<$Res>  {
  factory $OnboardingModelCopyWith(OnboardingModel value, $Res Function(OnboardingModel) _then) = _$OnboardingModelCopyWithImpl;
@useResult
$Res call({
 int currentStepIndex, bool resuming, Map<String, OnboardingStepStatus> stepStatus, Map<String, dynamic> answers
});




}
/// @nodoc
class _$OnboardingModelCopyWithImpl<$Res>
    implements $OnboardingModelCopyWith<$Res> {
  _$OnboardingModelCopyWithImpl(this._self, this._then);

  final OnboardingModel _self;
  final $Res Function(OnboardingModel) _then;

/// Create a copy of OnboardingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStepIndex = null,Object? resuming = null,Object? stepStatus = null,Object? answers = null,}) {
  return _then(_self.copyWith(
currentStepIndex: null == currentStepIndex ? _self.currentStepIndex : currentStepIndex // ignore: cast_nullable_to_non_nullable
as int,resuming: null == resuming ? _self.resuming : resuming // ignore: cast_nullable_to_non_nullable
as bool,stepStatus: null == stepStatus ? _self.stepStatus : stepStatus // ignore: cast_nullable_to_non_nullable
as Map<String, OnboardingStepStatus>,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingModel].
extension OnboardingModelPatterns on OnboardingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingModel value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingModel value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStepIndex,  bool resuming,  Map<String, OnboardingStepStatus> stepStatus,  Map<String, dynamic> answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingModel() when $default != null:
return $default(_that.currentStepIndex,_that.resuming,_that.stepStatus,_that.answers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStepIndex,  bool resuming,  Map<String, OnboardingStepStatus> stepStatus,  Map<String, dynamic> answers)  $default,) {final _that = this;
switch (_that) {
case _OnboardingModel():
return $default(_that.currentStepIndex,_that.resuming,_that.stepStatus,_that.answers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStepIndex,  bool resuming,  Map<String, OnboardingStepStatus> stepStatus,  Map<String, dynamic> answers)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingModel() when $default != null:
return $default(_that.currentStepIndex,_that.resuming,_that.stepStatus,_that.answers);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingModel implements OnboardingModel {
  const _OnboardingModel({this.currentStepIndex = 0, this.resuming = true, final  Map<String, OnboardingStepStatus> stepStatus = const <String, OnboardingStepStatus>{}, final  Map<String, dynamic> answers = const <String, dynamic>{}}): _stepStatus = stepStatus,_answers = answers;
  

/// The index, into `OnboardingController.steps`, of the step currently
/// shown.
@override@JsonKey() final  int currentStepIndex;
/// Whether the initial resume-from-persistence read is still in
/// flight — `true` only for the brief window between construction and
/// `OnboardingController.init` finishing.
@override@JsonKey() final  bool resuming;
/// Every step's persisted status so far, keyed by `OnboardingStep.id`.
/// A step with no entry has neither been completed nor skipped.
 final  Map<String, OnboardingStepStatus> _stepStatus;
/// Every step's persisted status so far, keyed by `OnboardingStep.id`.
/// A step with no entry has neither been completed nor skipped.
@override@JsonKey() Map<String, OnboardingStepStatus> get stepStatus {
  if (_stepStatus is EqualUnmodifiableMapView) return _stepStatus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stepStatus);
}

/// Every step's persisted answer so far, keyed by `OnboardingStep.id`.
 final  Map<String, dynamic> _answers;
/// Every step's persisted answer so far, keyed by `OnboardingStep.id`.
@override@JsonKey() Map<String, dynamic> get answers {
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_answers);
}


/// Create a copy of OnboardingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingModelCopyWith<_OnboardingModel> get copyWith => __$OnboardingModelCopyWithImpl<_OnboardingModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingModel&&(identical(other.currentStepIndex, currentStepIndex) || other.currentStepIndex == currentStepIndex)&&(identical(other.resuming, resuming) || other.resuming == resuming)&&const DeepCollectionEquality().equals(other._stepStatus, _stepStatus)&&const DeepCollectionEquality().equals(other._answers, _answers));
}


@override
int get hashCode => Object.hash(runtimeType,currentStepIndex,resuming,const DeepCollectionEquality().hash(_stepStatus),const DeepCollectionEquality().hash(_answers));

@override
String toString() {
  return 'OnboardingModel(currentStepIndex: $currentStepIndex, resuming: $resuming, stepStatus: $stepStatus, answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$OnboardingModelCopyWith<$Res> implements $OnboardingModelCopyWith<$Res> {
  factory _$OnboardingModelCopyWith(_OnboardingModel value, $Res Function(_OnboardingModel) _then) = __$OnboardingModelCopyWithImpl;
@override @useResult
$Res call({
 int currentStepIndex, bool resuming, Map<String, OnboardingStepStatus> stepStatus, Map<String, dynamic> answers
});




}
/// @nodoc
class __$OnboardingModelCopyWithImpl<$Res>
    implements _$OnboardingModelCopyWith<$Res> {
  __$OnboardingModelCopyWithImpl(this._self, this._then);

  final _OnboardingModel _self;
  final $Res Function(_OnboardingModel) _then;

/// Create a copy of OnboardingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStepIndex = null,Object? resuming = null,Object? stepStatus = null,Object? answers = null,}) {
  return _then(_OnboardingModel(
currentStepIndex: null == currentStepIndex ? _self.currentStepIndex : currentStepIndex // ignore: cast_nullable_to_non_nullable
as int,resuming: null == resuming ? _self.resuming : resuming // ignore: cast_nullable_to_non_nullable
as bool,stepStatus: null == stepStatus ? _self._stepStatus : stepStatus // ignore: cast_nullable_to_non_nullable
as Map<String, OnboardingStepStatus>,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
