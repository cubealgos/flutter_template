/// The Appwrite calls `DeletionService` needs, behind an interface so its
/// deletion logic can be unit-tested with a fake — no live Appwrite
/// instance required. `AppwriteAccountDeletionGateway` is the real
/// implementation, backed by `package:dart_appwrite`.
abstract class AccountDeletionGateway {
  /// Deletes every row in [tableId] whose [userIdColumn] equals [userId],
  /// and returns each deleted row's data (so the caller can pull file IDs
  /// out of it without this interface needing to know column semantics).
  Future<List<Map<String, dynamic>>> deleteOwnedRows({
    required String tableId,
    required String userIdColumn,
    required String userId,
  });

  /// Deletes one file. Never throws if the file is already gone (the
  /// implementation treats a 404 as success — the desired end state, a
  /// missing file, already holds).
  Future<void> deleteFile({required String bucketId, required String fileId});

  /// Deletes the user account itself.
  Future<void> deleteUser(String userId);
}
