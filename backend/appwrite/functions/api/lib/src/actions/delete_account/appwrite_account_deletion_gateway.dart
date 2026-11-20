import 'dart:io';

import 'package:api/src/actions/delete_account/account_deletion_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The real [AccountDeletionGateway], backed by `package:dart_appwrite`'s
/// `TablesDB`, `Storage` and `Users` services.
class AppwriteAccountDeletionGateway implements AccountDeletionGateway {
  /// Creates a gateway for [databaseId], backed by [client].
  ///
  /// [client] should be built with the per-execution API key from the
  /// `x-appwrite-key` request header (see `lib/main.dart`) — a
  /// short-lived key scoped to this one execution, not a long-lived server
  /// key.
  AppwriteAccountDeletionGateway({
    required Client client,
    required this.databaseId,
  }) : _tablesDb = TablesDB(client),
       _storage = Storage(client),
       _users = Users(client);

  /// The database rows are deleted from.
  final String databaseId;
  final TablesDB _tablesDb;
  final Storage _storage;
  final Users _users;

  @override
  Future<List<Map<String, dynamic>>> deleteOwnedRows({
    required String tableId,
    required String userIdColumn,
    required String userId,
  }) async {
    final result = await _tablesDb.deleteRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: <String>[Query.equal(userIdColumn, userId)],
    );

    return result.rows.map((row) => row.data).toList();
  }

  @override
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    try {
      await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
    } on AppwriteException catch (e) {
      // Already gone is the desired end state - not a failure to surface.
      if (e.code == HttpStatus.notFound) return;
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _users.delete(userId: userId);
  }
}
