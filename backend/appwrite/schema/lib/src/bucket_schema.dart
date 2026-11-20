/// A Storage bucket.
class BucketSchema {
  /// Declares a bucket named [name] with ID [id].
  const BucketSchema({
    required this.id,
    required this.name,
    this.fileSecurity = true,
  });

  /// The bucket's ID.
  final String id;

  /// The bucket's display name.
  final String name;

  /// Whether individual file permissions apply (Appwrite's `fileSecurity`).
  final bool fileSecurity;
}
