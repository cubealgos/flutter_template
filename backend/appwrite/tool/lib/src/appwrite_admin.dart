import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/table_access.dart';

/// The Appwrite admin operations `Provisioner` needs, behind an interface so
/// idempotency logic can be unit-tested with `FakeAppwriteAdmin` — no live
/// Appwrite instance required. `DartAppwriteAdmin` is the real
/// implementation, backed by `package:dart_appwrite`.
abstract class AppwriteAdmin {
  /// Returns true if the database with [databaseId] already exists.
  Future<bool> databaseExists(String databaseId);

  /// Creates a database.
  Future<void> createDatabase({
    required String databaseId,
    required String name,
  });

  /// Returns true if the table exists in the database.
  Future<bool> tableExists({
    required String databaseId,
    required String tableId,
  });

  /// Creates an empty table with the client permissions [access] names.
  Future<void> createTable({
    required String databaseId,
    required String tableId,
    required String name,
    required TableAccess access,
  });

  /// Returns the table's current table-level permissions and `rowSecurity`.
  Future<TableSettings> tableSettings({
    required String databaseId,
    required String tableId,
  });

  /// Sets the table's table-level permissions and `rowSecurity` to what
  /// [access] requires; an update of an existing table, never a create.
  Future<void> updateTableAccess({
    required String databaseId,
    required String tableId,
    required TableAccess access,
  });

  /// Returns the keys of columns that already exist on the table.
  Future<Set<String>> existingColumnKeys({
    required String databaseId,
    required String tableId,
  });

  /// Creates one column and waits until it reports `available` (or times
  /// out) before returning, so a subsequent index can safely reference it.
  Future<void> createColumn({
    required String databaseId,
    required String tableId,
    required ColumnSchema column,
  });

  /// Returns true if the row [rowId] already exists in the table.
  Future<bool> rowExists({
    required String databaseId,
    required String tableId,
    required String rowId,
  });

  /// Creates one row with [rowId] and column values [data].
  Future<void> createRow({
    required String databaseId,
    required String tableId,
    required String rowId,
    required Map<String, Object> data,
  });

  /// Returns the keys of indexes that already exist on the table.
  Future<Set<String>> existingIndexKeys({
    required String databaseId,
    required String tableId,
  });

  /// Creates one index.
  Future<void> createIndex({
    required String databaseId,
    required String tableId,
    required TableIndexSchema index,
  });

  /// Returns true if the bucket already exists.
  Future<bool> bucketExists(String bucketId);

  /// Creates a bucket.
  Future<void> createBucket({
    required String bucketId,
    required String name,
    required bool fileSecurity,
  });

  /// Returns the function's current mutable settings, or null if it does
  /// not exist yet.
  Future<FunctionSettings?> getFunction(String functionId);

  /// Returns the IDs of every Function that exists in the project, declared
  /// in the schema or not - `Provisioner` deletes the undeclared ones.
  Future<Set<String>> listFunctionIds();

  /// Permanently deletes the function [functionId] with its deployments and
  /// variables. A no-op if it does not exist. `Provisioner` only ever calls
  /// this for a function the schema does not declare.
  Future<void> deleteFunction(String functionId);

  /// Creates a function from its schema.
  Future<void> createFunction(FunctionSchema function);

  /// Updates a function's mutable settings (name, execute roles, entrypoint,
  /// commands, timeout) to match its schema. Never changes the runtime —
  /// Appwrite functions are not designed to change runtime after creation.
  Future<void> updateFunction(FunctionSchema function);

  /// Returns the keys of variables already set on the function.
  Future<Set<String>> existingFunctionVariableKeys(String functionId);

  /// Sets one function environment variable; [secret] hides its value from
  /// every later read (Appwrite never returns it again).
  Future<void> createFunctionVariable({
    required String functionId,
    required String key,
    required String value,
    bool secret = false,
  });

  /// Returns true if the Messaging provider [providerId] exists.
  Future<bool> messagingProviderExists(String providerId);

  /// Creates the Messaging SMTP provider [providerId] from [settings].
  /// Appwrite hides the password on every later read, so an
  /// existing provider is never compared, only left alone.
  Future<void> createSmtpProvider({
    required String providerId,
    required String name,
    required MailSettings settings,
  });

  /// Returns the IDs of every auth method (e.g. `"email-password"`,
  /// `"email-otp"`) currently enabled for the project — see
  /// `Provisioner`'s `unusedAuthMethods` for why this matters.
  Future<Set<String>> enabledAuthMethods();

  /// Disables auth method [methodId] for the project. Appwrite enables
  /// every auth method by default on a new project; a no-op if [methodId]
  /// is already disabled.
  Future<void> disableAuthMethod(String methodId);
}

/// A function's current mutable settings, as read back from Appwrite —
/// enough for `Provisioner` to detect drift without touching the runtime
/// (which never changes after creation).
class FunctionSettings {
  /// Creates a settings snapshot.
  const FunctionSettings({
    required this.name,
    required this.execute,
    required this.entrypoint,
    required this.commands,
    required this.timeout,
    required this.scopes,
    this.schedule = '',
  });

  /// The function's display name.
  final String name;

  /// Execution permission roles.
  final List<String> execute;

  /// The entrypoint file inside the deployment.
  final String entrypoint;

  /// The build command.
  final String commands;

  /// Execution timeout in seconds.
  final int timeout;

  /// The scopes granted to this function's per-execution API key — see
  /// `FunctionSchema.scopes`.
  final List<String> scopes;

  /// The cron expression, or the empty string for none.
  final String schedule;
}
