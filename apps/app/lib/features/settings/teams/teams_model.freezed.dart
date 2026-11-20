// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teams_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TeamsModel {

/// The active team's ID, if it is one of [teams].
 String? get activeTeamId;/// The teams the user belongs to.
 List<Team> get teams;/// Pending invitations addressed to the user's email.
 List<Invitation> get invitations;/// Whether the lists are still loading.
 bool get loading;/// Whether a create/accept/switch call is running.
 bool get busy;/// Whether the last call failed.
 bool get failed;
/// Create a copy of TeamsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamsModelCopyWith<TeamsModel> get copyWith => _$TeamsModelCopyWithImpl<TeamsModel>(this as TeamsModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamsModel&&(identical(other.activeTeamId, activeTeamId) || other.activeTeamId == activeTeamId)&&const DeepCollectionEquality().equals(other.teams, teams)&&const DeepCollectionEquality().equals(other.invitations, invitations)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,activeTeamId,const DeepCollectionEquality().hash(teams),const DeepCollectionEquality().hash(invitations),loading,busy,failed);

@override
String toString() {
  return 'TeamsModel(activeTeamId: $activeTeamId, teams: $teams, invitations: $invitations, loading: $loading, busy: $busy, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $TeamsModelCopyWith<$Res>  {
  factory $TeamsModelCopyWith(TeamsModel value, $Res Function(TeamsModel) _then) = _$TeamsModelCopyWithImpl;
@useResult
$Res call({
 String? activeTeamId, List<Team> teams, List<Invitation> invitations, bool loading, bool busy, bool failed
});




}
/// @nodoc
class _$TeamsModelCopyWithImpl<$Res>
    implements $TeamsModelCopyWith<$Res> {
  _$TeamsModelCopyWithImpl(this._self, this._then);

  final TeamsModel _self;
  final $Res Function(TeamsModel) _then;

/// Create a copy of TeamsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeTeamId = freezed,Object? teams = null,Object? invitations = null,Object? loading = null,Object? busy = null,Object? failed = null,}) {
  return _then(_self.copyWith(
activeTeamId: freezed == activeTeamId ? _self.activeTeamId : activeTeamId // ignore: cast_nullable_to_non_nullable
as String?,teams: null == teams ? _self.teams : teams // ignore: cast_nullable_to_non_nullable
as List<Team>,invitations: null == invitations ? _self.invitations : invitations // ignore: cast_nullable_to_non_nullable
as List<Invitation>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamsModel].
extension TeamsModelPatterns on TeamsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamsModel value)  $default,){
final _that = this;
switch (_that) {
case _TeamsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamsModel value)?  $default,){
final _that = this;
switch (_that) {
case _TeamsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? activeTeamId,  List<Team> teams,  List<Invitation> invitations,  bool loading,  bool busy,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamsModel() when $default != null:
return $default(_that.activeTeamId,_that.teams,_that.invitations,_that.loading,_that.busy,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? activeTeamId,  List<Team> teams,  List<Invitation> invitations,  bool loading,  bool busy,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _TeamsModel():
return $default(_that.activeTeamId,_that.teams,_that.invitations,_that.loading,_that.busy,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? activeTeamId,  List<Team> teams,  List<Invitation> invitations,  bool loading,  bool busy,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _TeamsModel() when $default != null:
return $default(_that.activeTeamId,_that.teams,_that.invitations,_that.loading,_that.busy,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _TeamsModel implements TeamsModel {
  const _TeamsModel({this.activeTeamId, final  List<Team> teams = const <Team>[], final  List<Invitation> invitations = const <Invitation>[], this.loading = true, this.busy = false, this.failed = false}): _teams = teams,_invitations = invitations;
  

/// The active team's ID, if it is one of [teams].
@override final  String? activeTeamId;
/// The teams the user belongs to.
 final  List<Team> _teams;
/// The teams the user belongs to.
@override@JsonKey() List<Team> get teams {
  if (_teams is EqualUnmodifiableListView) return _teams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teams);
}

/// Pending invitations addressed to the user's email.
 final  List<Invitation> _invitations;
/// Pending invitations addressed to the user's email.
@override@JsonKey() List<Invitation> get invitations {
  if (_invitations is EqualUnmodifiableListView) return _invitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invitations);
}

/// Whether the lists are still loading.
@override@JsonKey() final  bool loading;
/// Whether a create/accept/switch call is running.
@override@JsonKey() final  bool busy;
/// Whether the last call failed.
@override@JsonKey() final  bool failed;

/// Create a copy of TeamsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamsModelCopyWith<_TeamsModel> get copyWith => __$TeamsModelCopyWithImpl<_TeamsModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamsModel&&(identical(other.activeTeamId, activeTeamId) || other.activeTeamId == activeTeamId)&&const DeepCollectionEquality().equals(other._teams, _teams)&&const DeepCollectionEquality().equals(other._invitations, _invitations)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,activeTeamId,const DeepCollectionEquality().hash(_teams),const DeepCollectionEquality().hash(_invitations),loading,busy,failed);

@override
String toString() {
  return 'TeamsModel(activeTeamId: $activeTeamId, teams: $teams, invitations: $invitations, loading: $loading, busy: $busy, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$TeamsModelCopyWith<$Res> implements $TeamsModelCopyWith<$Res> {
  factory _$TeamsModelCopyWith(_TeamsModel value, $Res Function(_TeamsModel) _then) = __$TeamsModelCopyWithImpl;
@override @useResult
$Res call({
 String? activeTeamId, List<Team> teams, List<Invitation> invitations, bool loading, bool busy, bool failed
});




}
/// @nodoc
class __$TeamsModelCopyWithImpl<$Res>
    implements _$TeamsModelCopyWith<$Res> {
  __$TeamsModelCopyWithImpl(this._self, this._then);

  final _TeamsModel _self;
  final $Res Function(_TeamsModel) _then;

/// Create a copy of TeamsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeTeamId = freezed,Object? teams = null,Object? invitations = null,Object? loading = null,Object? busy = null,Object? failed = null,}) {
  return _then(_TeamsModel(
activeTeamId: freezed == activeTeamId ? _self.activeTeamId : activeTeamId // ignore: cast_nullable_to_non_nullable
as String?,teams: null == teams ? _self._teams : teams // ignore: cast_nullable_to_non_nullable
as List<Team>,invitations: null == invitations ? _self._invitations : invitations // ignore: cast_nullable_to_non_nullable
as List<Invitation>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
