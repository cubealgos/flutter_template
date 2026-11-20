/// A column on a user-owned table that holds a file ID in [bucketId] —
/// deleted alongside the owning row by `delete_account`.
class OwnedFileRef {
  /// Declares that [column] holds a file ID in [bucketId].
  const OwnedFileRef({required this.column, required this.bucketId});

  /// The table column holding the file ID (nullable columns are skipped at
  /// deletion time when empty).
  final String column;

  /// The bucket the file lives in.
  final String bucketId;
}
