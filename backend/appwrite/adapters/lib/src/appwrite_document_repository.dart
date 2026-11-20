import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_adapters/src/appwrite_data_error_mapping.dart';
import 'package:appwrite_adapters/src/appwrite_document_permissions.dart';
import 'package:appwrite_adapters/src/appwrite_query_mapping.dart';
import 'package:appwrite_adapters/src/appwrite_version_check.dart';
import 'package:appwrite_adapters/src/current_appwrite_user_id.dart';
import 'package:data/data.dart';

/// The default column name [AppwriteDocumentRepository] uses to scope rows
/// to their creator.
const String defaultOwnerColumn = 'userId';

/// The default column name [AppwriteDocumentRepository] uses to carry a
/// team-scoped row's team ID.
const String defaultTeamColumn = 'teamId';

/// The HTTP status Appwrite returns when a client asks for a permission it
/// doesn't hold itself.
const int _unauthorizedStatusCode = 401;

/// The [DocumentRepository] implementation backed by Appwrite's `TablesDB`
/// service.
///
/// One instance is scoped to one [databaseId]/[tableId]. "Scoped to the
/// current user" (see [DocumentRepository]'s dartdoc) is enforced two
/// ways, together: [create] writes [ownerColumn] (the calling user's ID)
/// into the row and sets per-row read/update/delete permissions to that
/// user (`Role.user`) — Appwrite itself then excludes rows the caller
/// isn't permitted to read from [query]'s results and refuses
/// [read]/[update]/[delete] on a row it isn't permitted to touch. Both
/// only take effect if the target table has row security enabled and
/// grants authenticated users table-level **create only** — never read,
/// update or delete, which are blanket grants over every row and would
/// defeat the per-row permissions. This template's own
/// `bin/provision.dart` does this for every table it creates (see
/// `backend/appwrite/tool/lib/src/dart_appwrite_admin.dart`'s
/// `createTable`). [query] additionally filters by [ownerColumn] (or, for a
/// [TeamScope], [teamColumn]) itself as a defense-in-depth backstop, in
/// case a target table doesn't have row security on.
///
/// **Team-scoped rows** ([TeamScope]) get `Role.team(teamId[, role])`
/// permissions instead, so every member of the team (or every member holding
/// the named role) reads them, and a member who is removed loses access at
/// once. Appwrite lets a client grant only roles it holds itself, so a member
/// can't scope a row to a team they aren't in, nor to a role they lack; the
/// resulting 401 is reported as [DataPermissionError]. A table that holds
/// team rows needs a [teamColumn] column. Which role strings exist is
/// the `team_admin` action's business (see `nativeTeamRole`).
class AppwriteDocumentRepository implements DocumentRepository {
  /// Creates a repository for [tableId] in [databaseId].
  AppwriteDocumentRepository(
    Client client, {
    required this.databaseId,
    required this.tableId,
    this.ownerColumn = defaultOwnerColumn,
    this.teamColumn = defaultTeamColumn,
  }) : _tablesDb = TablesDB(client),
       _account = Account(client);

  /// The `TablesDB` database ID.
  final String databaseId;

  /// The table this repository reads and writes.
  final String tableId;

  /// The column [create] writes the calling user's ID into.
  final String ownerColumn;

  /// The column [create] writes a [TeamScope]'s team ID into.
  final String teamColumn;

  final TablesDB _tablesDb;
  final Account _account;

  @override
  Future<Document> create(
    Map<String, dynamic> data, {
    String? id,
    DocumentScope scope = const UserScope(),
  }) async {
    final userId = await currentAppwriteUserId(_account);
    final rowData = <String, dynamic>{
      ...data,
      ownerColumn: userId,
      if (scope is TeamScope) teamColumn: scope.teamId,
    };

    try {
      final row = await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id ?? ID.unique(),
        data: rowData,
        permissions: appwritePermissionsFor(scope, userId),
      );

      return _toDocument(row);
    } on AppwriteException catch (e) {
      if (scope is TeamScope && e.code == _unauthorizedStatusCode) {
        throw DataPermissionError(
          e.message ?? 'Not allowed to scope a row to this team or role.',
        );
      }
      throw mapAppwriteDataError(e);
    }
  }

  @override
  Future<Document> read(String id) async {
    try {
      final row = await _tablesDb.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
      );

      return _toDocument(row);
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  @override
  Future<List<Document>> query([
    DataQuery query = const DataQuery(),
    DocumentScope scope = const UserScope(),
  ]) async {
    final userId = await currentAppwriteUserId(_account);
    final queries = <String>[
      ...buildAppwriteQueries(query),
      switch (scope) {
        UserScope() => Query.equal(ownerColumn, userId),
        TeamScope(:final teamId) => Query.equal(teamColumn, teamId),
      },
    ];

    try {
      final result = await _tablesDb.listRows(
        databaseId: databaseId,
        tableId: tableId,
        queries: queries,
      );

      return result.rows.map(_toDocument).toList();
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  /// Replaces the document's fields.
  ///
  /// **Optimistic concurrency without compare-and-set.** TablesDB has no
  /// conditional update, so with [expectedVersion] (a `Document.version`,
  /// which here is the row's `$updatedAt`) this reads the row, refuses with
  /// [DataConflictError] unless its `$updatedAt` still equals
  /// [expectedVersion], and only then writes. Two saves that both pass the
  /// read inside the same few milliseconds can still both win; this closes
  /// the realistic window (a stale form saved minutes later), not the race
  /// itself. State that needs a hard guarantee must change through an `api`
  /// action that serialises on a unique row (see `JobQueueEngine`).
  @override
  Future<Document> update(
    String id,
    Map<String, dynamic> data, {
    String? expectedVersion,
  }) async {
    try {
      if (expectedVersion != null) {
        final current = await _tablesDb.getRow(
          databaseId: databaseId,
          tableId: tableId,
          rowId: id,
        );
        requireVersion(
          id,
          expected: expectedVersion,
          actual: current.$updatedAt,
        );
      }
      final row = await _tablesDb.updateRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
        data: data,
      );

      return _toDocument(row);
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _tablesDb.deleteRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: id,
      );
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  Document _toDocument(models.Row row) =>
      Document(id: row.$id, data: row.data, version: row.$updatedAt);
}
