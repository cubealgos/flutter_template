import 'dart:io';

import 'package:api/src/retention/retention_store.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// Rows fetched and deleted per page.
const int _pageSize = 100;

/// The most pages one run deletes, so a huge backlog is worked off over
/// several runs instead of exceeding the Function's timeout.
const int maxRetentionPagesPerRun = 50;

/// The [RetentionStore] over Appwrite `TablesDB`: lists a page of rows
/// older than the cutoff (the column needs an index) and deletes them one by
/// one, until none are left or [maxRetentionPagesPerRun] pages were done.
class AppwriteRetentionStore implements RetentionStore {
  /// Creates a store over [client] for [databaseId].
  AppwriteRetentionStore({required Client client, required this.databaseId})
    : _tablesDb = TablesDB(client);

  /// The database holding the tables.
  final String databaseId;

  final TablesDB _tablesDb;

  @override
  Future<int> deleteOlderThan({
    required String table,
    required String column,
    required DateTime cutoff,
  }) async {
    var deleted = 0;
    for (var page = 0; page < maxRetentionPagesPerRun; page++) {
      final rows = await _tablesDb.listRows(
        databaseId: databaseId,
        tableId: table,
        queries: <String>[
          Query.lessThan(column, cutoff.toUtc().toIso8601String()),
          Query.limit(_pageSize),
        ],
      );
      for (final row in rows.rows) {
        try {
          await _tablesDb.deleteRow(
            databaseId: databaseId,
            tableId: table,
            rowId: row.$id,
          );
          deleted++;
        } on AppwriteException catch (e) {
          // Already gone (a concurrent run): that is the goal.
          if (e.code != HttpStatus.notFound) rethrow;
        }
      }
      if (rows.rows.length < _pageSize) break;
    }

    return deleted;
  }
}
