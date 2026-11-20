/// Metadata for one file uploaded through a `StorageService`.
class StoredFile {
  /// Creates a stored-file record.
  const StoredFile({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
  });

  /// The file's ID, unique within its bucket.
  final String id;

  /// The original file name, as passed to `StorageService.upload`.
  final String fileName;

  /// The file's size in bytes.
  final int sizeBytes;

  @override
  String toString() =>
      'StoredFile(id: $id, fileName: $fileName, sizeBytes: $sizeBytes)';
}
