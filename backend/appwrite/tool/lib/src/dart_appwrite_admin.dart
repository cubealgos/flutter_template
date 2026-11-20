import 'dart:convert';
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/table_access.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart' as enums;
import 'package:http/http.dart' as http;

/// How long [DartAppwriteAdmin] waits for a freshly created column to report
/// `available` before giving up and creating a dependent index anyway (the
/// index create call will itself fail clearly if the column truly isn't
/// ready, rather than this silently hanging forever on a stuck column).
const int _columnAvailabilityTimeoutSeconds = 30;

/// How long [DartAppwriteAdmin] waits between polls of a column's status
/// while it waits for [_columnAvailabilityTimeoutSeconds] to elapse.
const int _columnPollIntervalMilliseconds = 500;

/// The inclusive lower bound of an HTTP "success" status code.
const int _httpSuccessRangeStart = 200;

/// The exclusive upper bound of an HTTP "success" status code.
const int _httpSuccessRangeEndExclusive = 300;

/// The HTTP status a create call gets back for "this resource already
/// exists" — see [DartAppwriteAdmin.createFunction]'s dartdoc.
const int _conflictStatusCode = 409;

/// The HTTP status of "no such resource".
const int _notFoundStatusCode = 404;

/// How many Functions one `Functions.list` page asks for (Appwrite's own
/// maximum is 5000; the Free plan allows 2, a paid one far fewer than this).
const int _functionPageSize = 100;

/// The real [AppwriteAdmin], backed by `package:dart_appwrite`'s `TablesDB`,
/// `Storage` and `Functions` services.
///
/// Function create/update deliberately bypass the typed `Functions` service
/// for the `runtime` field and go through raw REST calls instead — see
/// `FunctionSchema.runtime`'s dartdoc for why (`dart_appwrite` 29.0.0's
/// `enums.Runtime` originally lacked the runtime the template needed; it now
/// has `dart312`, but the raw REST path is kept). Every other Functions
/// operation (variables) uses the typed service normally.
class DartAppwriteAdmin implements AppwriteAdmin {
  /// Creates an admin backed by [client], which must already have its
  /// endpoint, project and API key set (see
  /// `package:appwrite_tool/src/backend_env.dart`).
  DartAppwriteAdmin(this.client)
    : _tablesDb = TablesDB(client),
      _storage = Storage(client),
      _functions = Functions(client),
      _messaging = Messaging(client),
      _project = Project(client);

  /// The configured Appwrite client.
  final Client client;
  final TablesDB _tablesDb;
  final Storage _storage;
  final Functions _functions;
  final Messaging _messaging;
  final Project _project;

  @override
  Future<bool> databaseExists(String databaseId) async {
    try {
      await _tablesDb.get(databaseId: databaseId);

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return false;
      rethrow;
    }
  }

  @override
  Future<void> createDatabase({
    required String databaseId,
    required String name,
  }) async {
    await _tablesDb.create(databaseId: databaseId, name: name);
  }

  @override
  Future<bool> tableExists({
    required String databaseId,
    required String tableId,
  }) async {
    try {
      await _tablesDb.getTable(databaseId: databaseId, tableId: tableId);

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return false;
      rethrow;
    }
  }

  @override
  Future<void> createTable({
    required String databaseId,
    required String tableId,
    required String name,
    required TableAccess access,
  }) async {
    // Table-level `create(Role.users())` only, plus `rowSecurity: true`
    // (see `TableAccess` for the rule and why). A
    // table-level permission is a blanket grant over every row, so
    // granting read/update/delete here would let every signed-in user
    // touch every row, whatever the per-row permissions say - row
    // security only *adds* narrower per-row grants. Without any
    // table-level permission a real (non-admin) session gets
    // `general_unauthorized_scope`/403 on every TablesDB call (found by
    // hand), so `create` is the one grant that lets a user attempt
    // a row create; the row's own `Permission.read/update/delete(
    // Role.user(userId))` (set by `AppwriteDocumentRepository.create`)
    // then scopes it to its owner. `TableAccess.publicRead` adds
    // `read(Role.any())`: deliberately, every row of that table is then
    // readable by anyone; `serverOnly` grants nothing at all.
    await _tablesDb.createTable(
      databaseId: databaseId,
      tableId: tableId,
      name: name,
      rowSecurity: tableRowSecurity,
      permissions: tablePermissions(access),
    );
  }

  @override
  Future<TableSettings> tableSettings({
    required String databaseId,
    required String tableId,
  }) async {
    final table = await _tablesDb.getTable(
      databaseId: databaseId,
      tableId: tableId,
    );

    return TableSettings(
      permissions: table.$permissions,
      rowSecurity: table.rowSecurity,
    );
  }

  @override
  Future<void> updateTableAccess({
    required String databaseId,
    required String tableId,
    required TableAccess access,
  }) async {
    await _tablesDb.updateTable(
      databaseId: databaseId,
      tableId: tableId,
      rowSecurity: tableRowSecurity,
      permissions: tablePermissions(access),
    );
  }

  @override
  Future<Set<String>> existingColumnKeys({
    required String databaseId,
    required String tableId,
  }) async {
    final result = await _tablesDb.listColumns(
      databaseId: databaseId,
      tableId: tableId,
    );

    return result.columns
        .map(
          (dynamic column) => (column as Map<String, dynamic>)['key'] as String,
        )
        .toSet();
  }

  @override
  Future<void> createColumn({
    required String databaseId,
    required String tableId,
    required ColumnSchema column,
  }) async {
    await _createColumnByType(
      databaseId: databaseId,
      tableId: tableId,
      column: column,
    );
    await _waitForColumnAvailable(
      databaseId: databaseId,
      tableId: tableId,
      key: column.key,
    );
  }

  Future<void> _createColumnByType({
    required String databaseId,
    required String tableId,
    required ColumnSchema column,
  }) async {
    switch (column.type) {
      case ColumnType.text:
        await _tablesDb.createTextColumn(
          databaseId: databaseId,
          tableId: tableId,
          key: column.key,
          xrequired: column.isRequired,
          array: column.isArray,
        );
      case ColumnType.varchar:
        await _tablesDb.createVarcharColumn(
          databaseId: databaseId,
          tableId: tableId,
          key: column.key,
          size: column.size,
          xrequired: column.isRequired,
          array: column.isArray,
        );
      case ColumnType.boolean:
        await _tablesDb.createBooleanColumn(
          databaseId: databaseId,
          tableId: tableId,
          key: column.key,
          xrequired: column.isRequired,
          array: column.isArray,
        );
      case ColumnType.datetime:
        await _tablesDb.createDatetimeColumn(
          databaseId: databaseId,
          tableId: tableId,
          key: column.key,
          xrequired: column.isRequired,
          array: column.isArray,
        );
    }
  }

  Future<void> _waitForColumnAvailable({
    required String databaseId,
    required String tableId,
    required String key,
  }) async {
    const timeout = Duration(seconds: _columnAvailabilityTimeoutSeconds);
    const pollInterval = Duration(
      milliseconds: _columnPollIntervalMilliseconds,
    );
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await _tablesDb.listColumns(
        databaseId: databaseId,
        tableId: tableId,
      );
      final match = result.columns.cast<Map<String, dynamic>>().where(
        (column) => column['key'] == key,
      );
      if (match.isNotEmpty && match.first['status'] == 'available') return;
      await Future<void>.delayed(pollInterval);
    }
  }

  @override
  Future<bool> rowExists({
    required String databaseId,
    required String tableId,
    required String rowId,
  }) async {
    try {
      await _tablesDb.getRow(
        databaseId: databaseId,
        tableId: tableId,
        rowId: rowId,
      );

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return false;
      rethrow;
    }
  }

  @override
  Future<void> createRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    required Map<String, Object> data,
  }) async {
    await _tablesDb.createRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: rowId,
      data: data,
    );
  }

  @override
  Future<Set<String>> existingIndexKeys({
    required String databaseId,
    required String tableId,
  }) async {
    final result = await _tablesDb.listIndexes(
      databaseId: databaseId,
      tableId: tableId,
    );

    return result.indexes.map((index) => index.key).toSet();
  }

  @override
  Future<void> createIndex({
    required String databaseId,
    required String tableId,
    required TableIndexSchema index,
  }) async {
    await _tablesDb.createIndex(
      databaseId: databaseId,
      tableId: tableId,
      key: index.key,
      type: index.unique
          ? enums.TablesDBIndexType.unique
          : enums.TablesDBIndexType.key,
      columns: index.columns,
    );
  }

  @override
  Future<bool> bucketExists(String bucketId) async {
    try {
      await _storage.getBucket(bucketId: bucketId);

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return false;
      rethrow;
    }
  }

  @override
  Future<void> createBucket({
    required String bucketId,
    required String name,
    required bool fileSecurity,
  }) async {
    // Same reasoning as `createTable`'s `permissions:` above: a
    // bucket-level grant is what lets a real (non-admin) user session
    // attempt `Storage.createFile`/`getFileDownload`/`deleteFile` at all;
    // per-file permissions (set by `AppwriteStorageService.upload`) then
    // scope each file to its own owner once [fileSecurity] is on.
    await _storage.createBucket(
      bucketId: bucketId,
      name: name,
      fileSecurity: fileSecurity,
      permissions: <String>[
        Permission.create(Role.users()),
        Permission.read(Role.users()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
      ],
    );
  }

  @override
  Future<FunctionSettings?> getFunction(String functionId) async {
    try {
      final function = await _functions.get(functionId: functionId);

      return FunctionSettings(
        name: function.name,
        execute: function.execute,
        entrypoint: function.entrypoint,
        commands: function.commands,
        timeout: function.timeout,
        scopes: function.scopes,
        schedule: function.schedule,
      );
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<Set<String>> listFunctionIds() async {
    final ids = <String>{};
    while (true) {
      final page = await _functions.list(
        queries: <String>[
          Query.limit(_functionPageSize),
          Query.offset(ids.length),
        ],
      );
      ids.addAll(page.functions.map((function) => function.$id));
      if (page.functions.length < _functionPageSize) return ids;
    }
  }

  @override
  Future<void> deleteFunction(String functionId) async {
    try {
      await _functions.delete(functionId: functionId);
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return;
      rethrow;
    }
  }

  @override
  Future<void> createFunction(FunctionSchema function) async {
    final response = await http.post(
      _restUri('/functions'),
      headers: _restHeaders(),
      body: jsonEncode(<String, dynamic>{
        'functionId': function.id,
        'name': function.name,
        'runtime': function.runtime,
        'execute': function.execute,
        'entrypoint': function.entrypoint,
        'commands': function.commands,
        'timeout': function.timeout,
        'scopes': function.scopes,
        'schedule': function.schedule,
      }),
    );
    // 409 `function_already_exists` here means a concurrent provisioning
    // run (e.g. two `backend/appwrite/tool/test/integration/` files each calling
    // `Provisioner.run()` against the same live instance) won the race to
    // create this exact function between `Provisioner._provisionFunction`'s
    // own `getFunction` check and this call - the desired end state (the
    // function exists) already holds, so this isn't a failure worth
    // surfacing. Live-reproduced
    // running this suite (the integration tests added a second
    // and third concurrent `Provisioner.run()` caller in that directory).
    if (response.statusCode == _conflictStatusCode) return;
    _checkRestResponse(response, action: 'create function ${function.id}');
  }

  @override
  Future<void> updateFunction(FunctionSchema function) async {
    final response = await http.put(
      _restUri('/functions/${function.id}'),
      headers: _restHeaders(),
      body: jsonEncode(<String, dynamic>{
        'name': function.name,
        'execute': function.execute,
        'entrypoint': function.entrypoint,
        'commands': function.commands,
        'timeout': function.timeout,
        'scopes': function.scopes,
        'schedule': function.schedule,
      }),
    );
    _checkRestResponse(response, action: 'update function ${function.id}');
  }

  Uri _restUri(String path) => Uri.parse('${client.endPoint}$path');

  Map<String, String> _restHeaders() => <String, String>{
    'X-Appwrite-Project': client.config['project'] ?? '',
    'X-Appwrite-Key': client.config['key'] ?? '',
    'content-type': 'application/json',
    'accept': 'application/json',
  };

  void _checkRestResponse(http.Response response, {required String action}) {
    final status = response.statusCode;
    final isSuccess =
        status >= _httpSuccessRangeStart &&
        status < _httpSuccessRangeEndExclusive;
    if (isSuccess) return;
    throw AppwriteException('Failed to $action: ${response.body}', status);
  }

  @override
  Future<Set<String>> existingFunctionVariableKeys(String functionId) async {
    final result = await _functions.listVariables(functionId: functionId);

    return result.variables.map((variable) => variable.key).toSet();
  }

  @override
  Future<void> createFunctionVariable({
    required String functionId,
    required String key,
    required String value,
    bool secret = false,
  }) async {
    await _functions.createVariable(
      functionId: functionId,
      variableId: ID.unique(),
      key: key,
      value: value,
      secret: secret,
    );
  }

  @override
  Future<bool> messagingProviderExists(String providerId) async {
    try {
      await _messaging.getProvider(providerId: providerId);

      return true;
    } on AppwriteException catch (e) {
      if (e.code == _notFoundStatusCode) return false;
      rethrow;
    }
  }

  @override
  Future<void> createSmtpProvider({
    required String providerId,
    required String name,
    required MailSettings settings,
  }) async {
    await _messaging.createSMTPProvider(
      providerId: providerId,
      name: name,
      host: settings.host,
      port: settings.port,
      username: settings.username,
      password: settings.password,
      encryption: settings.implicitTls
          ? enums.SmtpEncryption.ssl
          : enums.SmtpEncryption.tls,
      fromEmail: settings.fromEmail,
      fromName: settings.fromName,
      enabled: true,
    );
  }

  @override
  Future<Set<String>> enabledAuthMethods() async {
    final project = await _project.get();

    return project.authMethods
        .where((method) => method.enabled)
        .map((method) => method.$id.value)
        .toSet();
  }

  @override
  Future<void> disableAuthMethod(String methodId) async {
    final id = enums.ProjectAuthMethodId.values.firstWhere(
      (candidate) => candidate.value == methodId,
      orElse: () => throw ArgumentError('Unknown auth method "$methodId".'),
    );
    await _project.updateAuthMethod(methodId: id, enabled: false);
  }
}
