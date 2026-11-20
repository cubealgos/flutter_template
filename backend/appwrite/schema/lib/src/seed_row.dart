/// One row `TableSchema.seedRows` asks provisioning to create when it is
/// absent — and never to touch again once it exists.
class SeedRow {
  /// Declares a row with the fixed ID [id] and column values [data].
  const SeedRow({required this.id, required this.data});

  /// The row's fixed ID (e.g. `'default'` for `app_config`).
  final String id;

  /// Column key to value. Must satisfy the table's required columns.
  final Map<String, Object> data;
}
