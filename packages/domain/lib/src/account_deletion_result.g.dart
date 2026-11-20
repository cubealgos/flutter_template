// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountDeletionResult _$AccountDeletionResultFromJson(
  Map<String, dynamic> json,
) => _AccountDeletionResult(
  userId: json['userId'] as String,
  deletedAt: DateTime.parse(json['deletedAt'] as String),
  userDeleted: json['userDeleted'] as bool,
  removedRows:
      (json['removedRows'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  removedFiles:
      (json['removedFiles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
);

Map<String, dynamic> _$AccountDeletionResultToJson(
  _AccountDeletionResult instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'deletedAt': instance.deletedAt.toIso8601String(),
  'userDeleted': instance.userDeleted,
  'removedRows': instance.removedRows,
  'removedFiles': instance.removedFiles,
};
