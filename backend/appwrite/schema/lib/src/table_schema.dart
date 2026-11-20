import 'package:appwrite_schema/src/column_schema.dart';
import 'package:appwrite_schema/src/seed_row.dart';
import 'package:appwrite_schema/src/table_index_schema.dart';
import 'package:appwrite_schema/src/table_ownership.dart';

/// A `TablesDB` table (Appwrite's renamed "collection").
class TableSchema {
  /// Declares a table named [name] with ID [id].
  const TableSchema({
    required this.id,
    required this.name,
    required this.columns,
    this.ownership,
    this.indexes = const [],
    this.publicRead = false,
    this.serverOnly = false,
    this.seedRows = const [],
  });

  /// The table's ID.
  final String id;

  /// The table's display name.
  final String name;

  /// The table's columns.
  final List<ColumnSchema> columns;

  /// The table's indexes.
  final List<TableIndexSchema> indexes;

  /// If set, this table is user-owned — see [TableOwnership].
  final TableOwnership? ownership;

  /// Whether every row is readable by anyone, signed in or not
  /// (`Permission.read(Role.any())` on top of the signed-in
  /// table-level `create` grant — see `TableAccess` in `backend/`). This
  /// deliberately makes every row of the table public.
  ///
  /// For a table with no [ownership] and a small, fixed set of rows a
  /// backend administrator manages directly (e.g. `app_config`, read by
  /// the bootstrap/splash screen's `VersionPolicy` check before any
  /// session exists) — never for a user-owned table, since that would
  /// expose every user's rows to everyone.
  final bool publicRead;

  /// Whether only server-side code (a Function's API key) may touch this
  /// table: provisioning grants no table-level permission to any client, and
  /// rows are created without per-row permissions, so no signed-in user can
  /// create, read, change or delete a row. For state a Function owns and
  /// clients must not forge or read directly, such as `team_invitations` and
  /// `team_membership_events`.
  final bool serverOnly;

  /// Rows provisioning creates when absent (matched by [SeedRow.id]) and
  /// never overwrites once present, so an administrator's later edits to
  /// them survive every re-run.
  final List<SeedRow> seedRows;
}
