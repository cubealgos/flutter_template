// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'members_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MembersModel {

/// The active team, or null if there is none (or it can't be read).
 Team? get team;/// The current user's role in [team], or null while unknown.
 String? get myRole;/// The team's members.
 List<Membership> get members;/// The team's invitations still waiting for an answer. Empty unless the
/// current user is the owner or an admin, who alone may list them.
 List<Invitation> get pendingInvitations;/// Whether the lists are still loading.
 bool get loading;/// Whether an invite/revoke call is running.
 bool get busy;/// Whether the last call failed.
 bool get failed;
/// Create a copy of MembersModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembersModelCopyWith<MembersModel> get copyWith => _$MembersModelCopyWithImpl<MembersModel>(this as MembersModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembersModel&&(identical(other.team, team) || other.team == team)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&const DeepCollectionEquality().equals(other.members, members)&&const DeepCollectionEquality().equals(other.pendingInvitations, pendingInvitations)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,team,myRole,const DeepCollectionEquality().hash(members),const DeepCollectionEquality().hash(pendingInvitations),loading,busy,failed);

@override
String toString() {
  return 'MembersModel(team: $team, myRole: $myRole, members: $members, pendingInvitations: $pendingInvitations, loading: $loading, busy: $busy, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $MembersModelCopyWith<$Res>  {
  factory $MembersModelCopyWith(MembersModel value, $Res Function(MembersModel) _then) = _$MembersModelCopyWithImpl;
@useResult
$Res call({
 Team? team, String? myRole, List<Membership> members, List<Invitation> pendingInvitations, bool loading, bool busy, bool failed
});




}
/// @nodoc
class _$MembersModelCopyWithImpl<$Res>
    implements $MembersModelCopyWith<$Res> {
  _$MembersModelCopyWithImpl(this._self, this._then);

  final MembersModel _self;
  final $Res Function(MembersModel) _then;

/// Create a copy of MembersModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? team = freezed,Object? myRole = freezed,Object? members = null,Object? pendingInvitations = null,Object? loading = null,Object? busy = null,Object? failed = null,}) {
  return _then(_self.copyWith(
team: freezed == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team?,myRole: freezed == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<Membership>,pendingInvitations: null == pendingInvitations ? _self.pendingInvitations : pendingInvitations // ignore: cast_nullable_to_non_nullable
as List<Invitation>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MembersModel].
extension MembersModelPatterns on MembersModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembersModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembersModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembersModel value)  $default,){
final _that = this;
switch (_that) {
case _MembersModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembersModel value)?  $default,){
final _that = this;
switch (_that) {
case _MembersModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Team? team,  String? myRole,  List<Membership> members,  List<Invitation> pendingInvitations,  bool loading,  bool busy,  bool failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembersModel() when $default != null:
return $default(_that.team,_that.myRole,_that.members,_that.pendingInvitations,_that.loading,_that.busy,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Team? team,  String? myRole,  List<Membership> members,  List<Invitation> pendingInvitations,  bool loading,  bool busy,  bool failed)  $default,) {final _that = this;
switch (_that) {
case _MembersModel():
return $default(_that.team,_that.myRole,_that.members,_that.pendingInvitations,_that.loading,_that.busy,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Team? team,  String? myRole,  List<Membership> members,  List<Invitation> pendingInvitations,  bool loading,  bool busy,  bool failed)?  $default,) {final _that = this;
switch (_that) {
case _MembersModel() when $default != null:
return $default(_that.team,_that.myRole,_that.members,_that.pendingInvitations,_that.loading,_that.busy,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _MembersModel extends MembersModel {
  const _MembersModel({this.team, this.myRole, final  List<Membership> members = const <Membership>[], final  List<Invitation> pendingInvitations = const <Invitation>[], this.loading = true, this.busy = false, this.failed = false}): _members = members,_pendingInvitations = pendingInvitations,super._();
  

/// The active team, or null if there is none (or it can't be read).
@override final  Team? team;
/// The current user's role in [team], or null while unknown.
@override final  String? myRole;
/// The team's members.
 final  List<Membership> _members;
/// The team's members.
@override@JsonKey() List<Membership> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

/// The team's invitations still waiting for an answer. Empty unless the
/// current user is the owner or an admin, who alone may list them.
 final  List<Invitation> _pendingInvitations;
/// The team's invitations still waiting for an answer. Empty unless the
/// current user is the owner or an admin, who alone may list them.
@override@JsonKey() List<Invitation> get pendingInvitations {
  if (_pendingInvitations is EqualUnmodifiableListView) return _pendingInvitations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInvitations);
}

/// Whether the lists are still loading.
@override@JsonKey() final  bool loading;
/// Whether an invite/revoke call is running.
@override@JsonKey() final  bool busy;
/// Whether the last call failed.
@override@JsonKey() final  bool failed;

/// Create a copy of MembersModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembersModelCopyWith<_MembersModel> get copyWith => __$MembersModelCopyWithImpl<_MembersModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembersModel&&(identical(other.team, team) || other.team == team)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._pendingInvitations, _pendingInvitations)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,team,myRole,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_pendingInvitations),loading,busy,failed);

@override
String toString() {
  return 'MembersModel(team: $team, myRole: $myRole, members: $members, pendingInvitations: $pendingInvitations, loading: $loading, busy: $busy, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$MembersModelCopyWith<$Res> implements $MembersModelCopyWith<$Res> {
  factory _$MembersModelCopyWith(_MembersModel value, $Res Function(_MembersModel) _then) = __$MembersModelCopyWithImpl;
@override @useResult
$Res call({
 Team? team, String? myRole, List<Membership> members, List<Invitation> pendingInvitations, bool loading, bool busy, bool failed
});




}
/// @nodoc
class __$MembersModelCopyWithImpl<$Res>
    implements _$MembersModelCopyWith<$Res> {
  __$MembersModelCopyWithImpl(this._self, this._then);

  final _MembersModel _self;
  final $Res Function(_MembersModel) _then;

/// Create a copy of MembersModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? team = freezed,Object? myRole = freezed,Object? members = null,Object? pendingInvitations = null,Object? loading = null,Object? busy = null,Object? failed = null,}) {
  return _then(_MembersModel(
team: freezed == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team?,myRole: freezed == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<Membership>,pendingInvitations: null == pendingInvitations ? _self._pendingInvitations : pendingInvitations // ignore: cast_nullable_to_non_nullable
as List<Invitation>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
