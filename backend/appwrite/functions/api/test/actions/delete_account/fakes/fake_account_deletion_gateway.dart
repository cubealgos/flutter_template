import 'package:api/src/actions/delete_account/account_deletion_gateway.dart';

/// An in-memory [AccountDeletionGateway] fake for testing `DeletionService`
/// without a live Appwrite instance.
class FakeAccountDeletionGateway implements AccountDeletionGateway {
  /// Seeds table `tableId` with rows already "owned" by some user, keyed
  /// by user ID, so [deleteOwnedRows] has something to return.
  final Map<String, Map<String, List<Map<String, dynamic>>>> rowsByTable =
      <String, Map<String, List<Map<String, dynamic>>>>{};

  /// File IDs "deleted" so far, as `bucketId/fileId`.
  final List<String> deletedFiles = <String>[];

  /// User IDs [deleteUser] was called with.
  final List<String> deletedUsers = <String>[];

  /// If set, [deleteUser] throws this instead of succeeding.
  Exception? deleteUserError;

  /// Seeds [tableId] with [rows] owned by [userId].
  void seedRows({
    required String tableId,
    required String userId,
    required List<Map<String, dynamic>> rows,
  }) {
    rowsByTable.putIfAbsent(
      tableId,
      () => <String, List<Map<String, dynamic>>>{},
    )[userId] = rows;
  }

  @override
  Future<List<Map<String, dynamic>>> deleteOwnedRows({
    required String tableId,
    required String userIdColumn,
    required String userId,
  }) async {
    final byUser = rowsByTable[tableId];
    if (byUser == null) return <Map<String, dynamic>>[];

    return byUser.remove(userId) ?? <Map<String, dynamic>>[];
  }

  @override
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    deletedFiles.add('$bucketId/$fileId');
  }

  @override
  Future<void> deleteUser(String userId) async {
    final error = deleteUserError;
    if (error != null) throw error;
    deletedUsers.add(userId);
  }
}
