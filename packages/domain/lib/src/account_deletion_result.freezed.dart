// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_deletion_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountDeletionResult {

/// The Appwrite user ID that was deleted.
 String get userId;/// When the deletion ran, in UTC.
 DateTime get deletedAt;/// Whether the underlying `Users.delete` call succeeded. `false` only
/// when owned rows/files were removed but the user account itself could
/// not be deleted (surfaced to the caller as a partial-failure result
/// rather than a thrown error, so the response always names what did
/// and didn't complete).
 bool get userDeleted;/// Rows/documents removed per table or collection ID, keyed by the
/// schema's declared ID (see `backend/appwrite/schema`'s
/// `templateSchema`).
 Map<String, int> get removedRows;/// Files removed per storage bucket ID, keyed by the schema's declared
/// ID.
 Map<String, int> get removedFiles;
/// Create a copy of AccountDeletionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDeletionResultCopyWith<AccountDeletionResult> get copyWith => _$AccountDeletionResultCopyWithImpl<AccountDeletionResult>(this as AccountDeletionResult, _$identity);

  /// Serializes this AccountDeletionResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeletionResult&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.userDeleted, userDeleted) || other.userDeleted == userDeleted)&&const DeepCollectionEquality().equals(other.removedRows, removedRows)&&const DeepCollectionEquality().equals(other.removedFiles, removedFiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,deletedAt,userDeleted,const DeepCollectionEquality().hash(removedRows),const DeepCollectionEquality().hash(removedFiles));

@override
String toString() {
  return 'AccountDeletionResult(userId: $userId, deletedAt: $deletedAt, userDeleted: $userDeleted, removedRows: $removedRows, removedFiles: $removedFiles)';
}


}

/// @nodoc
abstract mixin class $AccountDeletionResultCopyWith<$Res>  {
  factory $AccountDeletionResultCopyWith(AccountDeletionResult value, $Res Function(AccountDeletionResult) _then) = _$AccountDeletionResultCopyWithImpl;
@useResult
$Res call({
 String userId, DateTime deletedAt, bool userDeleted, Map<String, int> removedRows, Map<String, int> removedFiles
});




}
/// @nodoc
class _$AccountDeletionResultCopyWithImpl<$Res>
    implements $AccountDeletionResultCopyWith<$Res> {
  _$AccountDeletionResultCopyWithImpl(this._self, this._then);

  final AccountDeletionResult _self;
  final $Res Function(AccountDeletionResult) _then;

/// Create a copy of AccountDeletionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? deletedAt = null,Object? userDeleted = null,Object? removedRows = null,Object? removedFiles = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,deletedAt: null == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userDeleted: null == userDeleted ? _self.userDeleted : userDeleted // ignore: cast_nullable_to_non_nullable
as bool,removedRows: null == removedRows ? _self.removedRows : removedRows // ignore: cast_nullable_to_non_nullable
as Map<String, int>,removedFiles: null == removedFiles ? _self.removedFiles : removedFiles // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDeletionResult].
extension AccountDeletionResultPatterns on AccountDeletionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDeletionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDeletionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDeletionResult value)  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDeletionResult value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  DateTime deletedAt,  bool userDeleted,  Map<String, int> removedRows,  Map<String, int> removedFiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDeletionResult() when $default != null:
return $default(_that.userId,_that.deletedAt,_that.userDeleted,_that.removedRows,_that.removedFiles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  DateTime deletedAt,  bool userDeleted,  Map<String, int> removedRows,  Map<String, int> removedFiles)  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionResult():
return $default(_that.userId,_that.deletedAt,_that.userDeleted,_that.removedRows,_that.removedFiles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  DateTime deletedAt,  bool userDeleted,  Map<String, int> removedRows,  Map<String, int> removedFiles)?  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionResult() when $default != null:
return $default(_that.userId,_that.deletedAt,_that.userDeleted,_that.removedRows,_that.removedFiles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountDeletionResult implements AccountDeletionResult {
  const _AccountDeletionResult({required this.userId, required this.deletedAt, required this.userDeleted, final  Map<String, int> removedRows = const <String, int>{}, final  Map<String, int> removedFiles = const <String, int>{}}): _removedRows = removedRows,_removedFiles = removedFiles;
  factory _AccountDeletionResult.fromJson(Map<String, dynamic> json) => _$AccountDeletionResultFromJson(json);

/// The Appwrite user ID that was deleted.
@override final  String userId;
/// When the deletion ran, in UTC.
@override final  DateTime deletedAt;
/// Whether the underlying `Users.delete` call succeeded. `false` only
/// when owned rows/files were removed but the user account itself could
/// not be deleted (surfaced to the caller as a partial-failure result
/// rather than a thrown error, so the response always names what did
/// and didn't complete).
@override final  bool userDeleted;
/// Rows/documents removed per table or collection ID, keyed by the
/// schema's declared ID (see `backend/appwrite/schema`'s
/// `templateSchema`).
 final  Map<String, int> _removedRows;
/// Rows/documents removed per table or collection ID, keyed by the
/// schema's declared ID (see `backend/appwrite/schema`'s
/// `templateSchema`).
@override@JsonKey() Map<String, int> get removedRows {
  if (_removedRows is EqualUnmodifiableMapView) return _removedRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_removedRows);
}

/// Files removed per storage bucket ID, keyed by the schema's declared
/// ID.
 final  Map<String, int> _removedFiles;
/// Files removed per storage bucket ID, keyed by the schema's declared
/// ID.
@override@JsonKey() Map<String, int> get removedFiles {
  if (_removedFiles is EqualUnmodifiableMapView) return _removedFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_removedFiles);
}


/// Create a copy of AccountDeletionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDeletionResultCopyWith<_AccountDeletionResult> get copyWith => __$AccountDeletionResultCopyWithImpl<_AccountDeletionResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountDeletionResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDeletionResult&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.userDeleted, userDeleted) || other.userDeleted == userDeleted)&&const DeepCollectionEquality().equals(other._removedRows, _removedRows)&&const DeepCollectionEquality().equals(other._removedFiles, _removedFiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,deletedAt,userDeleted,const DeepCollectionEquality().hash(_removedRows),const DeepCollectionEquality().hash(_removedFiles));

@override
String toString() {
  return 'AccountDeletionResult(userId: $userId, deletedAt: $deletedAt, userDeleted: $userDeleted, removedRows: $removedRows, removedFiles: $removedFiles)';
}


}

/// @nodoc
abstract mixin class _$AccountDeletionResultCopyWith<$Res> implements $AccountDeletionResultCopyWith<$Res> {
  factory _$AccountDeletionResultCopyWith(_AccountDeletionResult value, $Res Function(_AccountDeletionResult) _then) = __$AccountDeletionResultCopyWithImpl;
@override @useResult
$Res call({
 String userId, DateTime deletedAt, bool userDeleted, Map<String, int> removedRows, Map<String, int> removedFiles
});




}
/// @nodoc
class __$AccountDeletionResultCopyWithImpl<$Res>
    implements _$AccountDeletionResultCopyWith<$Res> {
  __$AccountDeletionResultCopyWithImpl(this._self, this._then);

  final _AccountDeletionResult _self;
  final $Res Function(_AccountDeletionResult) _then;

/// Create a copy of AccountDeletionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? deletedAt = null,Object? userDeleted = null,Object? removedRows = null,Object? removedFiles = null,}) {
  return _then(_AccountDeletionResult(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,deletedAt: null == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userDeleted: null == userDeleted ? _self.userDeleted : userDeleted // ignore: cast_nullable_to_non_nullable
as bool,removedRows: null == removedRows ? _self._removedRows : removedRows // ignore: cast_nullable_to_non_nullable
as Map<String, int>,removedFiles: null == removedFiles ? _self._removedFiles : removedFiles // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
