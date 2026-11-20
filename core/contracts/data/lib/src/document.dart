/// One record from a `DocumentRepository`, backend-agnostic — an Appwrite
/// `TablesDB` row, mapped by `AppwriteDocumentRepository`, or an in-memory
/// entry from `FakeDocumentRepository`.
class Document {
  /// Creates a document with [id] and [data].
  const Document({required this.id, required this.data, this.version});

  /// The document's ID, unique within its collection.
  final String id;

  /// The document's fields. Deliberately `Map<String, dynamic>`, not a
  /// generic typed model: this package stays a thin CRUD/query surface
  /// (per the issue's "keep it small and honest" instruction), and an app
  /// maps this to its own typed model (e.g. one of `package:domain`'s)
  /// itself, the same way it already maps a JSON API response.
  final Map<String, dynamic> data;

  /// An opaque token that changes whenever the document is written, or null
  /// if the backend gave none. Pass it back as
  /// `DocumentRepository.update`'s `expectedVersion` to refuse the update if
  /// someone else saved in between. Compare it only for equality: Appwrite's
  /// is the row's `$updatedAt`, the fake's a counter.
  final String? version;

  @override
  String toString() => 'Document(id: $id, data: $data)';
}
