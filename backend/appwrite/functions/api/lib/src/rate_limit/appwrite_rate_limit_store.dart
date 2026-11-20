import 'dart:io';

import 'package:api/src/rate_limit/rate_limit_store.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The `rate_limits` table's ID.
const String rateLimitsTable = 'rate_limits';

/// The [RateLimitStore] over the `rate_limits` table, unique on (`keyHash`,
/// `windowStart`, `hit`); a taken hit is a 409.
class AppwriteRateLimitStore implements RateLimitStore {
  /// Creates a store over [client] for [databaseId].
  AppwriteRateLimitStore({required Client client, required this.databaseId})
    : _tablesDb = TablesDB(client);

  /// The database holding `rate_limits`.
  final String databaseId;

  final TablesDB _tablesDb;

  @override
  Future<int> hitsIn(String keyHash, int windowStart) async {
    final rows = await _tablesDb.listRows(
      databaseId: databaseId,
      tableId: rateLimitsTable,
      queries: <String>[
        Query.equal('keyHash', <String>[keyHash]),
        Query.equal('windowStart', <String>['$windowStart']),
        Query.limit(1),
      ],
    );

    return rows.total;
  }

  @override
  Future<bool> tryTake(
    String keyHash,
    int windowStart,
    int hit,
    DateTime expiresAt,
  ) async {
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: rateLimitsTable,
        rowId: ID.unique(),
        data: <String, dynamic>{
          'keyHash': keyHash,
          'windowStart': '$windowStart',
          'hit': '$hit',
          'expiresAt': expiresAt.toUtc().toIso8601String(),
        },
      );

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) return false;
      rethrow;
    }
  }
}
