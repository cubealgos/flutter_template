import 'dart:io';

import 'package:api/src/schedule/slot_store.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The `job_slots` table's ID.
const String jobSlotsTable = 'job_slots';

/// The longest row ID Appwrite accepts.
const int _maxRowIdLength = 36;

/// The [SlotStore] over the `job_slots` table, unique on (`jobName`,
/// `slot`): claiming is inserting the row, and a 409 means someone already
/// did. The row ID is the pair too, so the claim is atomic twice over.
class AppwriteSlotStore implements SlotStore {
  /// Creates a store over [client] for [databaseId].
  AppwriteSlotStore({required Client client, required this.databaseId})
    : _tablesDb = TablesDB(client);

  /// The database holding `job_slots`.
  final String databaseId;

  final TablesDB _tablesDb;

  /// Row IDs allow letters, digits and underscore, 36 characters at most.
  static String _rowId(String jobName, int slot) {
    final name = jobName.replaceAll(RegExp('[^A-Za-z0-9]'), '_');
    final id = '${name}_$slot';

    return id.length <= _maxRowIdLength
        ? id
        : id.substring(id.length - _maxRowIdLength);
  }

  @override
  Future<bool> claim(String jobName, int slot, DateTime now) async {
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: jobSlotsTable,
        rowId: _rowId(jobName, slot),
        data: <String, dynamic>{
          'jobName': jobName,
          'slot': '$slot',
          'claimedAt': now.toUtc().toIso8601String(),
        },
      );

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) return false;
      rethrow;
    }
  }

  @override
  Future<void> release(String jobName, int slot) async {
    try {
      await _tablesDb.deleteRow(
        databaseId: databaseId,
        tableId: jobSlotsTable,
        rowId: _rowId(jobName, slot),
      );
    } on AppwriteException catch (e) {
      if (e.code != HttpStatus.notFound) rethrow;
    }
  }
}
