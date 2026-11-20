import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// Who may reach a table, as provisioning sets it. The table-level
/// permission list of each value is pinned by `test/table_access_test.dart`.
///
/// **Rule: never grant read, update or delete at table level on a per-user
/// or per-team table.** A table-level permission is a blanket grant over
/// every row; row security only *adds* narrower per-row grants and never
/// withdraws a table-level one (the original
/// `read/update/delete(Role.users())` made every signed-in user able to
/// read, change and delete every other user's rows).
enum TableAccess {
  /// A per-user table: signed-in users may only create. Reading, updating
  /// and deleting a row comes solely from the row's own permissions (set at
  /// creation, e.g. `AppwriteDocumentRepository`).
  signedIn,

  /// Like [signedIn], plus every row is readable by anyone, signed in or
  /// not (`TableSchema.publicRead`). Deliberate: it makes every row public.
  publicRead,

  /// No client permission at all; only the server's API key reaches it.
  serverOnly,
}

/// The access `table` declares: `serverOnly` wins over `publicRead`.
TableAccess tableAccessOf(TableSchema table) => table.serverOnly
    ? TableAccess.serverOnly
    : (table.publicRead ? TableAccess.publicRead : TableAccess.signedIn);

/// The table-level permission strings provisioning sets for [access].
List<String> tablePermissions(TableAccess access) => switch (access) {
  TableAccess.signedIn => <String>[Permission.create(Role.users())],
  TableAccess.publicRead => <String>[
    Permission.create(Role.users()),
    Permission.read(Role.any()),
  ],
  TableAccess.serverOnly => const <String>[],
};

/// `rowSecurity` for every table: row permissions are what scope a signed-in
/// user's rows, and a table without row grants stays closed to clients
/// regardless.
const bool tableRowSecurity = true;

/// A table's current access settings, as read back from Appwrite.
class TableSettings {
  /// Creates a snapshot.
  const TableSettings({required this.permissions, required this.rowSecurity});

  /// The table-level permission strings.
  final List<String> permissions;

  /// Whether row-level permissions are enabled.
  final bool rowSecurity;
}

/// Whether [current] differs from what [access] requires. Permissions are
/// compared as sets (Appwrite does not order them); an empty expected list
/// (`serverOnly`) matches only an empty actual list, so an empty list never
/// counts as drift on a table that should have none, and any grant on it does.
bool tableAccessDrifted(TableSettings current, TableAccess access) {
  final expected = tablePermissions(access).toSet();
  final actual = current.permissions.toSet();

  return current.rowSecurity != tableRowSecurity ||
      !(expected.containsAll(actual) && actual.containsAll(expected));
}
