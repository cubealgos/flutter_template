import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/table_access.dart';

/// An [AppwriteAdmin] for `Provisioner` dry runs: reads go to [inner],
/// writes are only remembered (so later reads in the same run see them) and
/// never sent. `Provisioner.run`'s report then lists exactly what a real
/// run would change.
class DryRunAdmin implements AppwriteAdmin {
  /// Wraps [inner], which is only ever read from.
  DryRunAdmin(this.inner);

  /// The real admin, used for reads only.
  final AppwriteAdmin inner;

  final Set<String> _databases = <String>{};
  final Set<String> _tables = <String>{};
  final Map<String, Set<String>> _columns = <String, Set<String>>{};
  final Map<String, Set<String>> _indexes = <String, Set<String>>{};
  final Set<String> _rows = <String>{};
  final Set<String> _buckets = <String>{};
  final Set<String> _functions = <String>{};
  final Set<String> _deletedFunctions = <String>{};
  final Map<String, Set<String>> _variables = <String, Set<String>>{};
  final Set<String> _disabledMethods = <String>{};
  final Set<String> _providers = <String>{};

  /// Tables whose access a dry run "updated": later reads see the new access.
  final Map<String, TableAccess> _accessUpdates = <String, TableAccess>{};

  String _t(String d, String t) => '$d/$t';

  @override
  Future<bool> databaseExists(String databaseId) async =>
      _databases.contains(databaseId) || await inner.databaseExists(databaseId);

  @override
  Future<void> createDatabase({
    required String databaseId,
    required String name,
  }) async => _databases.add(databaseId);

  @override
  Future<bool> tableExists({
    required String databaseId,
    required String tableId,
  }) async =>
      _tables.contains(_t(databaseId, tableId)) ||
      (!_databases.contains(databaseId) &&
          await inner.tableExists(databaseId: databaseId, tableId: tableId));

  @override
  Future<void> createTable({
    required String databaseId,
    required String tableId,
    required String name,
    required TableAccess access,
  }) async => _tables.add(_t(databaseId, tableId));

  @override
  Future<TableSettings> tableSettings({
    required String databaseId,
    required String tableId,
  }) async {
    final updated = _accessUpdates[_t(databaseId, tableId)];
    if (updated == null) {
      return await inner.tableSettings(
        databaseId: databaseId,
        tableId: tableId,
      );
    }

    return TableSettings(
      permissions: tablePermissions(updated),
      rowSecurity: tableRowSecurity,
    );
  }

  @override
  Future<void> updateTableAccess({
    required String databaseId,
    required String tableId,
    required TableAccess access,
  }) async {
    _accessUpdates[_t(databaseId, tableId)] = access;
  }

  bool _createdHere(String databaseId, String tableId) =>
      _tables.contains(_t(databaseId, tableId));

  @override
  Future<Set<String>> existingColumnKeys({
    required String databaseId,
    required String tableId,
  }) async => <String>{
    if (!_createdHere(databaseId, tableId))
      ...await inner.existingColumnKeys(
        databaseId: databaseId,
        tableId: tableId,
      ),
    ...?_columns[_t(databaseId, tableId)],
  };

  @override
  Future<void> createColumn({
    required String databaseId,
    required String tableId,
    required ColumnSchema column,
  }) async => _columns
      .putIfAbsent(_t(databaseId, tableId), () => <String>{})
      .add(column.key);

  @override
  Future<bool> rowExists({
    required String databaseId,
    required String tableId,
    required String rowId,
  }) async =>
      _rows.contains('${_t(databaseId, tableId)}/$rowId') ||
      (!_createdHere(databaseId, tableId) &&
          await inner.rowExists(
            databaseId: databaseId,
            tableId: tableId,
            rowId: rowId,
          ));

  @override
  Future<void> createRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    required Map<String, Object> data,
  }) async => _rows.add('${_t(databaseId, tableId)}/$rowId');

  @override
  Future<Set<String>> existingIndexKeys({
    required String databaseId,
    required String tableId,
  }) async => <String>{
    if (!_createdHere(databaseId, tableId))
      ...await inner.existingIndexKeys(
        databaseId: databaseId,
        tableId: tableId,
      ),
    ...?_indexes[_t(databaseId, tableId)],
  };

  @override
  Future<void> createIndex({
    required String databaseId,
    required String tableId,
    required TableIndexSchema index,
  }) async => _indexes
      .putIfAbsent(_t(databaseId, tableId), () => <String>{})
      .add(index.key);

  @override
  Future<bool> bucketExists(String bucketId) async =>
      _buckets.contains(bucketId) || await inner.bucketExists(bucketId);

  @override
  Future<void> createBucket({
    required String bucketId,
    required String name,
    required bool fileSecurity,
  }) async => _buckets.add(bucketId);

  @override
  Future<FunctionSettings?> getFunction(String functionId) async =>
      _functions.contains(functionId) || _deletedFunctions.contains(functionId)
      ? null
      : await inner.getFunction(functionId);

  @override
  Future<Set<String>> listFunctionIds() async => <String>{
    ...await inner.listFunctionIds(),
    ..._functions,
  }.difference(_deletedFunctions);

  @override
  Future<void> deleteFunction(String functionId) async {
    _functions.remove(functionId);
    _deletedFunctions.add(functionId);
  }

  @override
  Future<void> createFunction(FunctionSchema function) async {
    _deletedFunctions.remove(function.id);
    _functions.add(function.id);
  }

  @override
  // A dry run never changes anything.
  Future<void> updateFunction(FunctionSchema function) => Future<void>.value();

  @override
  Future<Set<String>> existingFunctionVariableKeys(String functionId) async =>
      <String>{
        if (!_functions.contains(functionId) &&
            !_deletedFunctions.contains(functionId))
          ...await inner.existingFunctionVariableKeys(functionId),
        ...?_variables[functionId],
      };

  @override
  Future<void> createFunctionVariable({
    required String functionId,
    required String key,
    required String value,
    bool secret = false,
  }) async => _variables.putIfAbsent(functionId, () => <String>{}).add(key);

  @override
  Future<bool> messagingProviderExists(String providerId) async =>
      _providers.contains(providerId) ||
      await inner.messagingProviderExists(providerId);

  @override
  Future<void> createSmtpProvider({
    required String providerId,
    required String name,
    required MailSettings settings,
  }) async => _providers.add(providerId);

  @override
  Future<Set<String>> enabledAuthMethods() async =>
      (await inner.enabledAuthMethods()).difference(_disabledMethods);

  @override
  Future<void> disableAuthMethod(String methodId) async =>
      _disabledMethods.add(methodId);
}
