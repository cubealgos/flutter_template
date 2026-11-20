import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/table_access.dart';

/// An in-memory [AppwriteAdmin] fake for testing `Provisioner` without a
/// live Appwrite instance. Every "create" call also records itself in
/// [calls] so a test can assert exactly what happened, independent of
/// `ProvisionReport`.
class FakeAppwriteAdmin implements AppwriteAdmin {
  final Set<String> _databases = <String>{};
  final Set<String> _tables = <String>{};
  final Map<String, Set<String>> _columns = <String, Set<String>>{};
  final Map<String, Set<String>> _indexes = <String, Set<String>>{};
  final Map<String, Map<String, Object>> _rows =
      <String, Map<String, Object>>{};
  final Set<String> _buckets = <String>{};
  final Map<String, FunctionSettings> _functions = <String, FunctionSettings>{};
  final Map<String, Set<String>> _variables = <String, Set<String>>{};

  /// The Messaging provider IDs that exist, with the settings each was
  /// created from.
  final Map<String, MailSettings> providers = <String, MailSettings>{};

  /// The values of the variables [createFunctionVariable] created, by
  /// `function.key`, and which of them were secret.
  final Map<String, String> variableValues = <String, String>{};

  /// The `function.key` of every secret variable created.
  final Set<String> secretVariables = <String>{};

  /// The settings of each table, by `database/table`.
  final Map<String, TableSettings> _tableSettings = <String, TableSettings>{};

  /// Mirrors a real fresh Appwrite project: every auth method starts
  /// enabled (see `Provisioner.unusedAuthMethods`'s dartdoc).
  final Set<String> _enabledAuthMethods = <String>{
    'email-password',
    'magic-url',
    'email-otp',
    'anonymous',
    'invites',
    'jwt',
    'phone',
  };

  /// Every admin call made, in order, as a short description — for
  /// assertions on exactly what a `Provisioner.run()` did.
  final List<String> calls = <String>[];

  /// The table IDs [createTable] was called with `publicRead: true` for —
  /// lets a test assert `app_config` (and only `app_config`) was granted
  /// public read.
  final Set<String> publicReadTableIds = <String>{};

  /// The table IDs [createTable] was called with `serverOnly: true` for.
  final Set<String> serverOnlyTableIds = <String>{};

  /// The IDs of the Functions currently in the fake project.
  Set<String> get functionIds => _functions.keys.toSet();

  String _tableKey(String databaseId, String tableId) => '$databaseId/$tableId';

  @override
  Future<bool> databaseExists(String databaseId) async =>
      _databases.contains(databaseId);

  @override
  Future<void> createDatabase({
    required String databaseId,
    required String name,
  }) async {
    _databases.add(databaseId);
    calls.add('createDatabase($databaseId)');
  }

  @override
  Future<bool> tableExists({
    required String databaseId,
    required String tableId,
  }) async => _tables.contains(_tableKey(databaseId, tableId));

  @override
  Future<void> createTable({
    required String databaseId,
    required String tableId,
    required String name,
    required TableAccess access,
  }) async {
    _tables.add(_tableKey(databaseId, tableId));
    _tableSettings[_tableKey(databaseId, tableId)] = TableSettings(
      permissions: tablePermissions(access),
      rowSecurity: tableRowSecurity,
    );
    if (access == TableAccess.publicRead) publicReadTableIds.add(tableId);
    if (access == TableAccess.serverOnly) serverOnlyTableIds.add(tableId);
    calls.add('createTable($tableId)');
  }

  /// Overwrites a table's settings, as a console edit or a pre-fix
  /// provisioning would have left them - not recorded in [calls].
  void seedTableSettings(String tableId, TableSettings settings) =>
      _tableSettings[_tableKey('main', tableId)] = settings;

  /// The current settings of [tableId] in the `main` database.
  TableSettings? settingsOf(String tableId) =>
      _tableSettings[_tableKey('main', tableId)];

  @override
  Future<TableSettings> tableSettings({
    required String databaseId,
    required String tableId,
  }) async =>
      _tableSettings[_tableKey(databaseId, tableId)] ??
      (throw StateError('no such table $tableId'));

  @override
  Future<void> updateTableAccess({
    required String databaseId,
    required String tableId,
    required TableAccess access,
  }) async {
    _tableSettings[_tableKey(databaseId, tableId)] = TableSettings(
      permissions: tablePermissions(access),
      rowSecurity: tableRowSecurity,
    );
    calls.add('updateTableAccess($tableId)');
  }

  @override
  Future<Set<String>> existingColumnKeys({
    required String databaseId,
    required String tableId,
  }) async => _columns[_tableKey(databaseId, tableId)] ?? <String>{};

  @override
  Future<void> createColumn({
    required String databaseId,
    required String tableId,
    required ColumnSchema column,
  }) async {
    final key = _tableKey(databaseId, tableId);
    _columns.putIfAbsent(key, () => <String>{}).add(column.key);
    calls.add('createColumn($tableId.${column.key})');
  }

  /// The data of row [rowId] in [tableId] of the `main` database, or null.
  Map<String, Object>? rowData(String tableId, String rowId) =>
      _rows['$tableId/$rowId'];

  /// Pre-seeds a row, as an administrator's console edit would.
  void seedRow(String tableId, String rowId, Map<String, Object> data) =>
      _rows['$tableId/$rowId'] = data;

  @override
  Future<bool> rowExists({
    required String databaseId,
    required String tableId,
    required String rowId,
  }) async => _rows.containsKey('$tableId/$rowId');

  @override
  Future<void> createRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    required Map<String, Object> data,
  }) async {
    _rows['$tableId/$rowId'] = data;
    calls.add('createRow($tableId/$rowId)');
  }

  @override
  Future<Set<String>> existingIndexKeys({
    required String databaseId,
    required String tableId,
  }) async => _indexes[_tableKey(databaseId, tableId)] ?? <String>{};

  @override
  Future<void> createIndex({
    required String databaseId,
    required String tableId,
    required TableIndexSchema index,
  }) async {
    final key = _tableKey(databaseId, tableId);
    _indexes.putIfAbsent(key, () => <String>{}).add(index.key);
    calls.add('createIndex($tableId.${index.key})');
  }

  @override
  Future<bool> bucketExists(String bucketId) async =>
      _buckets.contains(bucketId);

  @override
  Future<void> createBucket({
    required String bucketId,
    required String name,
    required bool fileSecurity,
  }) async {
    _buckets.add(bucketId);
    calls.add('createBucket($bucketId)');
  }

  @override
  Future<FunctionSettings?> getFunction(String functionId) async =>
      _functions[functionId];

  /// Puts a Function straight into the fake project, as if created by hand
  /// in the console - not recorded in [calls].
  void seedFunction(String functionId) {
    _functions[functionId] = const FunctionSettings(
      name: 'seeded',
      execute: <String>[],
      entrypoint: 'lib/main.dart',
      commands: '',
      timeout: 15,
      scopes: <String>[],
    );
  }

  @override
  Future<Set<String>> listFunctionIds() async => _functions.keys.toSet();

  @override
  Future<void> deleteFunction(String functionId) async {
    _functions.remove(functionId);
    _variables.remove(functionId);
    calls.add('deleteFunction($functionId)');
  }

  @override
  Future<void> createFunction(FunctionSchema function) async =>
      _setFunction(function, callName: 'createFunction');

  @override
  Future<void> updateFunction(FunctionSchema function) async =>
      _setFunction(function, callName: 'updateFunction');

  void _setFunction(FunctionSchema function, {required String callName}) {
    _functions[function.id] = FunctionSettings(
      name: function.name,
      execute: function.execute,
      entrypoint: function.entrypoint,
      commands: function.commands,
      timeout: function.timeout,
      scopes: function.scopes,
      schedule: function.schedule,
    );
    calls.add('$callName(${function.id})');
  }

  @override
  Future<Set<String>> existingFunctionVariableKeys(String functionId) async =>
      _variables[functionId] ?? <String>{};

  @override
  Future<void> createFunctionVariable({
    required String functionId,
    required String key,
    required String value,
    bool secret = false,
  }) async {
    _variables.putIfAbsent(functionId, () => <String>{}).add(key);
    variableValues['$functionId.$key'] = value;
    if (secret) secretVariables.add('$functionId.$key');
    calls.add('createFunctionVariable($functionId.$key)');
  }

  @override
  Future<bool> messagingProviderExists(String providerId) async =>
      providers.containsKey(providerId);

  @override
  Future<void> createSmtpProvider({
    required String providerId,
    required String name,
    required MailSettings settings,
  }) async {
    providers[providerId] = settings;
    calls.add('createSmtpProvider($providerId)');
  }

  @override
  Future<Set<String>> enabledAuthMethods() async =>
      Set<String>.of(_enabledAuthMethods);

  @override
  Future<void> disableAuthMethod(String methodId) async {
    _enabledAuthMethods.remove(methodId);
    calls.add('disableAuthMethod($methodId)');
  }
}
