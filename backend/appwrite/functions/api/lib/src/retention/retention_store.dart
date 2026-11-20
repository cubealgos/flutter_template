/// Bulk deletion by age, the one thing `DeleteOlderThanRule` needs from a
/// backend.
abstract interface class RetentionStore {
  /// Deletes the rows of [table] whose [column] (a UTC ISO-8601 string) is
  /// before [cutoff], and returns how many it deleted. Idempotent.
  Future<int> deleteOlderThan({
    required String table,
    required String column,
    required DateTime cutoff,
  });
}
