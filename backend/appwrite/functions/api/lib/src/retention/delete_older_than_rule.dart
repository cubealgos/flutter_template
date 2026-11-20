import 'package:api/src/action_context.dart';
import 'package:api/src/retention/appwrite_retention_store.dart';
import 'package:api/src/retention/retention_rule.dart';
import 'package:api/src/retention/retention_store.dart';
import 'package:appwrite_schema/appwrite_schema.dart';

/// Builds the store a run uses, over [context]'s client.
typedef RetentionStoreFactory = RetentionStore Function(ActionContext context);

RetentionStore _appwriteStore(ActionContext context) => AppwriteRetentionStore(
  client: context.client,
  databaseId: templateSchema.databaseId,
);

/// Deletes the rows of [table] whose [column] is older than the period.
///
/// The period is [defaultPeriod] unless the Function variable [envKey] (whole
/// days) overrides it; a null period (no default and no variable) means keep
/// forever. [column] must hold a UTC ISO-8601 string and carry an index in
/// the schema. Deleting is idempotent.
class DeleteOlderThanRule implements RetentionRule {
  /// Creates the rule.
  const DeleteOlderThanRule({
    required this.table,
    required this.column,
    this.envKey,
    this.defaultPeriod,
    this.storeFor = _appwriteStore,
  });

  /// The table to clean.
  final String table;

  /// The timestamp column compared with the cutoff.
  final String column;

  /// The variable that overrides [defaultPeriod], in whole days.
  final String? envKey;

  /// The period when the variable is unset; null keeps rows forever.
  final Duration? defaultPeriod;

  /// Builds the store a run uses.
  final RetentionStoreFactory storeFor;

  @override
  String get name => table;

  @override
  Duration? periodFrom(Map<String, String> environment) {
    final key = envKey;
    final override = key == null ? null : retentionDaysFrom(environment, key);

    return override ?? defaultPeriod;
  }

  @override
  Future<int> apply(
    ActionContext context, {
    required DateTime now,
    required Duration period,
  }) => storeFor(
    context,
  ).deleteOlderThan(table: table, column: column, cutoff: now.subtract(period));
}
