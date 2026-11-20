import 'package:api/src/actions/delete_account/account_deletion_gateway.dart';
import 'package:api/src/actions/delete_account/account_owns_teams_exception.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:domain/domain.dart';
import 'package:teams/teams.dart';

/// Running counts of what a `DeletionService.deleteAccount` call removed,
/// mutated in place as each table is processed — exists purely to keep
/// `_deleteOwnedTableRows` under this workspace's 4-parameter limit
/// (`solid_lints/number_of_parameters`) instead of passing the two maps it
/// mutates as separate arguments.
class _DeletionTally {
  final Map<String, int> removedRows = <String, int>{};
  final Map<String, int> removedFiles = <String, int>{};

  void addRemovedRows(String tableId, int count) {
    removedRows[tableId] = count;
  }

  void addRemovedFiles(String bucketId, int count) {
    if (count == 0) return;
    removedFiles[bucketId] = (removedFiles[bucketId] ?? 0) + count;
  }
}

/// Deletes one user's owned rows, the files those rows reference, and
/// finally the user account itself — driven entirely by
/// [AppwriteSchema.tables]' ownership declarations, so this class has no
/// hard-coded knowledge of table or bucket names.
class DeletionService {
  /// Creates a deletion service applying [schema]'s ownership declarations
  /// through [gateway].
  const DeletionService({
    required this.gateway,
    required this.schema,
    required this.teams,
  });

  /// The Appwrite calls this service makes.
  final AccountDeletionGateway gateway;

  /// The schema whose `TableOwnership` declarations drive what gets
  /// deleted.
  final AppwriteSchema schema;

  /// The team rules: who owns which team. Deleting the user removes their
  /// native team memberships (Appwrite does that itself), which is fine for
  /// an admin or a member, whose team keeps its owner, and whose history
  /// entries stay (the history is append-only and outlives membership).
  final TeamEngine teams;

  /// Deletes [userId]'s owned rows and files, then the user account.
  ///
  /// **Refuses first**, before anything is deleted, with
  /// [AccountOwnsTeamsException] if [userId] owns any team.
  ///
  /// If [AccountDeletionGateway.deleteUser] throws, the rows and files
  /// already removed stay removed (there is no undo), and the returned
  /// result reports [AccountDeletionResult.userDeleted] as false rather
  /// than propagating the exception — the caller (`lib/main.dart`) always
  /// gets a well-formed result describing exactly what did and didn't
  /// complete.
  Future<AccountDeletionResult> deleteAccount(String userId) async {
    final owned = await teams.ownedTeams(userId);
    if (owned.isNotEmpty) {
      throw AccountOwnsTeamsException(<String>[for (final t in owned) t.name]);
    }

    final tally = _DeletionTally();

    for (final table in schema.tables) {
      final ownership = table.ownership;
      if (ownership == null) continue;
      await _deleteOwnedTableRows(
        table: table,
        ownership: ownership,
        userId: userId,
        tally: tally,
      );
    }

    final userDeleted = await _tryDeleteUser(userId);

    return AccountDeletionResult(
      userId: userId,
      deletedAt: DateTime.now().toUtc(),
      userDeleted: userDeleted,
      removedRows: tally.removedRows,
      removedFiles: tally.removedFiles,
    );
  }

  Future<void> _deleteOwnedTableRows({
    required TableSchema table,
    required TableOwnership ownership,
    required String userId,
    required _DeletionTally tally,
  }) async {
    final rows = await gateway.deleteOwnedRows(
      tableId: table.id,
      userIdColumn: ownership.userIdColumn,
      userId: userId,
    );
    if (rows.isEmpty) return;

    tally.addRemovedRows(table.id, rows.length);
    for (final fileRef in ownership.fileRefs) {
      final deletedCount = await _deleteReferencedFiles(fileRef, rows);
      tally.addRemovedFiles(fileRef.bucketId, deletedCount);
    }
  }

  Future<int> _deleteReferencedFiles(
    OwnedFileRef fileRef,
    List<Map<String, dynamic>> rows,
  ) async {
    var deletedCount = 0;
    for (final row in rows) {
      final fileId = row[fileRef.column] as String?;
      if (fileId == null || fileId.isEmpty) continue;
      await gateway.deleteFile(bucketId: fileRef.bucketId, fileId: fileId);
      deletedCount++;
    }

    return deletedCount;
  }

  Future<bool> _tryDeleteUser(String userId) async {
    try {
      await gateway.deleteUser(userId);

      return true;
    } on Exception {
      return false;
    }
  }
}
