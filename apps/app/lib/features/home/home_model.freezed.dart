// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeModel {

/// Whether the initial `UserPreferences` read for the setup card is
/// still in flight. The card never renders while this is `true`.
 bool get loadingSetupProgress;/// Every onboarding step that is neither completed nor skipped, in
/// stepper order — an empty list once nothing is left to finish.
 List<HomeSetupItem> get openSteps;/// How many onboarding steps are completed (not skipped) — the card's
/// "N of total done" line.
 int get completedStepCount;/// The total number of onboarding steps.
 int get totalStepCount;/// Whether the user dismissed the card this session (its own "X"
/// button) — not persisted: a fresh app start (or a step actually
/// finished) can show it again.
 bool get setupCardDismissed;
/// Create a copy of HomeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeModelCopyWith<HomeModel> get copyWith => _$HomeModelCopyWithImpl<HomeModel>(this as HomeModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeModel&&(identical(other.loadingSetupProgress, loadingSetupProgress) || other.loadingSetupProgress == loadingSetupProgress)&&const DeepCollectionEquality().equals(other.openSteps, openSteps)&&(identical(other.completedStepCount, completedStepCount) || other.completedStepCount == completedStepCount)&&(identical(other.totalStepCount, totalStepCount) || other.totalStepCount == totalStepCount)&&(identical(other.setupCardDismissed, setupCardDismissed) || other.setupCardDismissed == setupCardDismissed));
}


@override
int get hashCode => Object.hash(runtimeType,loadingSetupProgress,const DeepCollectionEquality().hash(openSteps),completedStepCount,totalStepCount,setupCardDismissed);

@override
String toString() {
  return 'HomeModel(loadingSetupProgress: $loadingSetupProgress, openSteps: $openSteps, completedStepCount: $completedStepCount, totalStepCount: $totalStepCount, setupCardDismissed: $setupCardDismissed)';
}


}

/// @nodoc
abstract mixin class $HomeModelCopyWith<$Res>  {
  factory $HomeModelCopyWith(HomeModel value, $Res Function(HomeModel) _then) = _$HomeModelCopyWithImpl;
@useResult
$Res call({
 bool loadingSetupProgress, List<HomeSetupItem> openSteps, int completedStepCount, int totalStepCount, bool setupCardDismissed
});




}
/// @nodoc
class _$HomeModelCopyWithImpl<$Res>
    implements $HomeModelCopyWith<$Res> {
  _$HomeModelCopyWithImpl(this._self, this._then);

  final HomeModel _self;
  final $Res Function(HomeModel) _then;

/// Create a copy of HomeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadingSetupProgress = null,Object? openSteps = null,Object? completedStepCount = null,Object? totalStepCount = null,Object? setupCardDismissed = null,}) {
  return _then(_self.copyWith(
loadingSetupProgress: null == loadingSetupProgress ? _self.loadingSetupProgress : loadingSetupProgress // ignore: cast_nullable_to_non_nullable
as bool,openSteps: null == openSteps ? _self.openSteps : openSteps // ignore: cast_nullable_to_non_nullable
as List<HomeSetupItem>,completedStepCount: null == completedStepCount ? _self.completedStepCount : completedStepCount // ignore: cast_nullable_to_non_nullable
as int,totalStepCount: null == totalStepCount ? _self.totalStepCount : totalStepCount // ignore: cast_nullable_to_non_nullable
as int,setupCardDismissed: null == setupCardDismissed ? _self.setupCardDismissed : setupCardDismissed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeModel].
extension HomeModelPatterns on HomeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeModel value)  $default,){
final _that = this;
switch (_that) {
case _HomeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeModel value)?  $default,){
final _that = this;
switch (_that) {
case _HomeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loadingSetupProgress,  List<HomeSetupItem> openSteps,  int completedStepCount,  int totalStepCount,  bool setupCardDismissed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeModel() when $default != null:
return $default(_that.loadingSetupProgress,_that.openSteps,_that.completedStepCount,_that.totalStepCount,_that.setupCardDismissed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loadingSetupProgress,  List<HomeSetupItem> openSteps,  int completedStepCount,  int totalStepCount,  bool setupCardDismissed)  $default,) {final _that = this;
switch (_that) {
case _HomeModel():
return $default(_that.loadingSetupProgress,_that.openSteps,_that.completedStepCount,_that.totalStepCount,_that.setupCardDismissed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loadingSetupProgress,  List<HomeSetupItem> openSteps,  int completedStepCount,  int totalStepCount,  bool setupCardDismissed)?  $default,) {final _that = this;
switch (_that) {
case _HomeModel() when $default != null:
return $default(_that.loadingSetupProgress,_that.openSteps,_that.completedStepCount,_that.totalStepCount,_that.setupCardDismissed);case _:
  return null;

}
}

}

/// @nodoc


class _HomeModel implements HomeModel {
  const _HomeModel({this.loadingSetupProgress = true, final  List<HomeSetupItem> openSteps = const <HomeSetupItem>[], this.completedStepCount = 0, this.totalStepCount = 0, this.setupCardDismissed = false}): _openSteps = openSteps;
  

/// Whether the initial `UserPreferences` read for the setup card is
/// still in flight. The card never renders while this is `true`.
@override@JsonKey() final  bool loadingSetupProgress;
/// Every onboarding step that is neither completed nor skipped, in
/// stepper order — an empty list once nothing is left to finish.
 final  List<HomeSetupItem> _openSteps;
/// Every onboarding step that is neither completed nor skipped, in
/// stepper order — an empty list once nothing is left to finish.
@override@JsonKey() List<HomeSetupItem> get openSteps {
  if (_openSteps is EqualUnmodifiableListView) return _openSteps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openSteps);
}

/// How many onboarding steps are completed (not skipped) — the card's
/// "N of total done" line.
@override@JsonKey() final  int completedStepCount;
/// The total number of onboarding steps.
@override@JsonKey() final  int totalStepCount;
/// Whether the user dismissed the card this session (its own "X"
/// button) — not persisted: a fresh app start (or a step actually
/// finished) can show it again.
@override@JsonKey() final  bool setupCardDismissed;

/// Create a copy of HomeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeModelCopyWith<_HomeModel> get copyWith => __$HomeModelCopyWithImpl<_HomeModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeModel&&(identical(other.loadingSetupProgress, loadingSetupProgress) || other.loadingSetupProgress == loadingSetupProgress)&&const DeepCollectionEquality().equals(other._openSteps, _openSteps)&&(identical(other.completedStepCount, completedStepCount) || other.completedStepCount == completedStepCount)&&(identical(other.totalStepCount, totalStepCount) || other.totalStepCount == totalStepCount)&&(identical(other.setupCardDismissed, setupCardDismissed) || other.setupCardDismissed == setupCardDismissed));
}


@override
int get hashCode => Object.hash(runtimeType,loadingSetupProgress,const DeepCollectionEquality().hash(_openSteps),completedStepCount,totalStepCount,setupCardDismissed);

@override
String toString() {
  return 'HomeModel(loadingSetupProgress: $loadingSetupProgress, openSteps: $openSteps, completedStepCount: $completedStepCount, totalStepCount: $totalStepCount, setupCardDismissed: $setupCardDismissed)';
}


}

/// @nodoc
abstract mixin class _$HomeModelCopyWith<$Res> implements $HomeModelCopyWith<$Res> {
  factory _$HomeModelCopyWith(_HomeModel value, $Res Function(_HomeModel) _then) = __$HomeModelCopyWithImpl;
@override @useResult
$Res call({
 bool loadingSetupProgress, List<HomeSetupItem> openSteps, int completedStepCount, int totalStepCount, bool setupCardDismissed
});




}
/// @nodoc
class __$HomeModelCopyWithImpl<$Res>
    implements _$HomeModelCopyWith<$Res> {
  __$HomeModelCopyWithImpl(this._self, this._then);

  final _HomeModel _self;
  final $Res Function(_HomeModel) _then;

/// Create a copy of HomeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadingSetupProgress = null,Object? openSteps = null,Object? completedStepCount = null,Object? totalStepCount = null,Object? setupCardDismissed = null,}) {
  return _then(_HomeModel(
loadingSetupProgress: null == loadingSetupProgress ? _self.loadingSetupProgress : loadingSetupProgress // ignore: cast_nullable_to_non_nullable
as bool,openSteps: null == openSteps ? _self._openSteps : openSteps // ignore: cast_nullable_to_non_nullable
as List<HomeSetupItem>,completedStepCount: null == completedStepCount ? _self.completedStepCount : completedStepCount // ignore: cast_nullable_to_non_nullable
as int,totalStepCount: null == totalStepCount ? _self.totalStepCount : totalStepCount // ignore: cast_nullable_to_non_nullable
as int,setupCardDismissed: null == setupCardDismissed ? _self.setupCardDismissed : setupCardDismissed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
