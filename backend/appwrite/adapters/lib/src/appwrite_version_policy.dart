import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/compare_dotted_versions.dart';
import 'package:data/data.dart';
import 'package:flutter/foundation.dart';

/// The default database/table/row IDs [AppwriteVersionPolicy] reads —
/// matching `backend/appwrite/schema`'s `templateSchema` `app_config`
/// table and its one fixed, admin-managed row.
const String defaultVersionPolicyDatabaseId = 'main';

/// See [defaultVersionPolicyDatabaseId].
const String defaultVersionPolicyTableId = 'app_config';

/// See [defaultVersionPolicyDatabaseId].
const String defaultVersionPolicyRowId = 'default';

/// Reads the version-policy row's column values, or `null` when the row does
/// not exist. May throw (the backend being unreachable, say).
typedef VersionRowReader = Future<Map<String, dynamic>?> Function();

/// The [VersionPolicy] implementation backed by Appwrite's `TablesDB`,
/// reading the publicly readable `app_config` row `backend/appwrite/schema`
/// declares (see `TableSchema.publicRead`) — works before any session
/// exists, since the bootstrap/splash screen's min-version check is the
/// very first thing that runs.
///
/// **Fails open.** Any error — the row not existing yet (an admin hasn't
/// configured it, or a clone hasn't run `bin/provision.dart`), the backend
/// being briefly unreachable, a malformed value — is treated as "not
/// blocked" rather than thrown: a misconfigured or momentarily-down version
/// check should never itself brick the app's bootstrap flow. [check]
/// therefore never throws.
///
/// **An absent row is not an error.** The row is fetched with a
/// `listRows` query on its ID rather than `getRow`: a missing row then comes
/// back as an empty `200` list instead of a `404`, which the browser would
/// log to the console as a failed request (app code cannot suppress that).
class AppwriteVersionPolicy implements VersionPolicy {
  /// Creates a policy reading [databaseId]/[tableId]/[rowId] through
  /// [client]. The defaults match `templateSchema`'s `app_config` table —
  /// override only if an app renamed it after cloning.
  AppwriteVersionPolicy(
    Client client, {
    this.databaseId = defaultVersionPolicyDatabaseId,
    this.tableId = defaultVersionPolicyTableId,
    this.rowId = defaultVersionPolicyRowId,
  }) : _readRow = _tablesDbRowReader(
         TablesDB(client),
         databaseId: databaseId,
         tableId: tableId,
         rowId: rowId,
       );

  /// Creates a policy that reads the row through [readRow] instead of a real
  /// `TablesDB` — for tests, with no Appwrite SDK involved.
  @visibleForTesting
  AppwriteVersionPolicy.withRowReader(VersionRowReader readRow)
    : databaseId = defaultVersionPolicyDatabaseId,
      tableId = defaultVersionPolicyTableId,
      rowId = defaultVersionPolicyRowId,
      _readRow = readRow;

  /// The database ID `app_config` lives in.
  final String databaseId;

  /// The table ID to read.
  final String tableId;

  /// The fixed row ID within [tableId]. `bin/provision.dart` creates it when
  /// absent (see `templateSchema`'s `seedRows`) and never overwrites it; a
  /// backend administrator then manages it directly (console or a script).
  final String rowId;

  final VersionRowReader _readRow;

  static VersionRowReader _tablesDbRowReader(
    TablesDB tablesDb, {
    required String databaseId,
    required String tableId,
    required String rowId,
  }) => () async {
    final rows = await tablesDb.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: <String>[Query.equal(r'$id', rowId), Query.limit(1)],
    );

    return rows.rows.isEmpty ? null : rows.rows.first.data;
  };

  @override
  Future<VersionCheckResult> check(String currentVersion) async {
    try {
      final data = await _readRow();
      if (data == null) return VersionCheckResult.allowed;

      return _evaluate(currentVersion, data);
    } on Object {
      // Not configured yet, unreachable, or a malformed value - fail open,
      // see this class's dartdoc.
      return VersionCheckResult.allowed;
    }
  }

  VersionCheckResult _evaluate(
    String currentVersion,
    Map<String, dynamic> data,
  ) {
    final minVersion = data['minSupportedVersion'] as String?;
    if (minVersion == null) return VersionCheckResult.allowed;
    if (compareDottedVersions(currentVersion, minVersion) >= 0) {
      return VersionCheckResult.allowed;
    }

    return VersionCheckResult(
      blocked: true,
      updateUrl: _updateUrl(data),
      message: data['message'] as String?,
    );
  }

  /// Picks the update link for the running platform out of the row's
  /// three per-platform columns — platform selection is a Flutter/UI
  /// concern this adapter (unlike `core/contracts/data`, a pure-Dart package) is
  /// allowed to make, since it already depends on Flutter for the
  /// `appwrite` client SDK.
  Uri? _updateUrl(Map<String, dynamic> data) {
    final key = kIsWeb
        ? 'updateUrlWeb'
        : switch (defaultTargetPlatform) {
            TargetPlatform.iOS => 'updateUrlIOS',
            TargetPlatform.android => 'updateUrlAndroid',
            _ => 'updateUrlWeb',
          };
    final value = data[key] as String?;

    return value == null || value.isEmpty ? null : Uri.tryParse(value);
  }
}
