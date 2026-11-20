import 'package:data/src/data_error.dart';
import 'package:data/src/data_query.dart';
import 'package:data/src/document.dart';
import 'package:data/src/document_scope.dart';

/// Document CRUD for one collection, scoped to the current user — or, for a
/// document created with a [TeamScope], to a team the user belongs to.
///
/// "Scoped to the current user" is an implementation contract, not a
/// parameter: a concrete `DocumentRepository` is constructed already bound
/// to both a collection and (via its backend's session) the signed-in
/// user, so its own permission rules — not caller-supplied filters — are
/// what keep one user from reading or writing another's documents. See
/// `AppwriteDocumentRepository`'s dartdoc for how the Appwrite adapter
/// enforces this.
abstract class DocumentRepository {
  /// Creates a document from [data]. [id] picks its ID explicitly; a null
  /// [id] lets the backend generate one. [scope] says whose it is: the
  /// current user's (the default) or a team's — see [DocumentScope].
  ///
  /// Throws [DataUnauthenticatedError] if there is no current user,
  /// [DataPermissionError] if [scope] names a team the user isn't in or a
  /// role they don't hold, or [DataNetworkError]/[DataUnknownError] for
  /// other failures.
  Future<Document> create(
    Map<String, dynamic> data, {
    String? id,
    DocumentScope scope = const UserScope(),
  });

  /// Reads the document with [id].
  ///
  /// Throws [DataNotFoundError] if it doesn't exist, or
  /// [DataPermissionError] if it exists but the current user may not read
  /// it (someone else's, or another team's).
  Future<Document> read(String id);

  /// Lists documents matching [query] (every one, by default) among those
  /// in [scope]: the current user's own (the default), or one team's.
  /// Documents the user may not read are never in the result.
  Future<List<Document>> query([
    DataQuery query = const DataQuery(),
    DocumentScope scope = const UserScope(),
  ]);

  /// Replaces the document with [id]'s fields with [data].
  ///
  /// With [expectedVersion] (the `Document.version` the caller last read) the
  /// update is optimistic: if the document has been written since, nothing
  /// is changed and [DataConflictError] is thrown, so the later of two
  /// concurrent saves is refused instead of silently overwriting the first.
  /// Without it the update always wins (last write wins).
  ///
  /// Throws [DataNotFoundError] if it doesn't exist,
  /// [DataPermissionError] if it isn't owned by the current user, or
  /// [DataConflictError] for a stale [expectedVersion].
  Future<Document> update(
    String id,
    Map<String, dynamic> data, {
    String? expectedVersion,
  });

  /// Deletes the document with [id]. Throws [DataNotFoundError] if it
  /// doesn't exist, or [DataPermissionError] if it isn't owned by the
  /// current user.
  Future<void> delete(String id);
}
