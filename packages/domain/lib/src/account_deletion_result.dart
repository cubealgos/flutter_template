import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_deletion_result.freezed.dart';
part 'account_deletion_result.g.dart';

/// The outcome of running the `delete_account` Appwrite Function for one
/// user.
///
/// Returned as the function's JSON response body (see
/// `backend/appwrite/functions/delete_account/lib/main.dart`) and consumed by the
/// app's Settings → Account → delete-account flow to confirm the deletion
/// actually happened rather than just that the HTTP call succeeded.
@freezed
abstract class AccountDeletionResult with _$AccountDeletionResult {
  /// Creates a deletion outcome.
  const factory AccountDeletionResult({
    /// The Appwrite user ID that was deleted.
    required String userId,

    /// When the deletion ran, in UTC.
    required DateTime deletedAt,

    /// Whether the underlying `Users.delete` call succeeded. `false` only
    /// when owned rows/files were removed but the user account itself could
    /// not be deleted (surfaced to the caller as a partial-failure result
    /// rather than a thrown error, so the response always names what did
    /// and didn't complete).
    required bool userDeleted,

    /// Rows/documents removed per table or collection ID, keyed by the
    /// schema's declared ID (see `backend/appwrite/schema`'s
    /// `templateSchema`).
    @Default(<String, int>{}) Map<String, int> removedRows,

    /// Files removed per storage bucket ID, keyed by the schema's declared
    /// ID.
    @Default(<String, int>{}) Map<String, int> removedFiles,
  }) = _AccountDeletionResult;

  /// Deserializes an [AccountDeletionResult] from the function's JSON
  /// response body.
  factory AccountDeletionResult.fromJson(Map<String, dynamic> json) =>
      _$AccountDeletionResultFromJson(json);
}
