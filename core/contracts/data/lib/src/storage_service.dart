import 'dart:typed_data';

import 'package:data/src/data_error.dart';
import 'package:data/src/stored_file.dart';

/// File upload/download/delete for one storage bucket, scoped to the
/// current user — see `DocumentRepository`'s dartdoc for what "scoped to
/// the current user" means for a concrete implementation.
abstract class StorageService {
  /// Uploads [bytes] as [fileName]. [id] picks the file's ID explicitly; a
  /// null [id] lets the backend generate one.
  ///
  /// Throws [DataUnauthenticatedError] if there is no current user.
  Future<StoredFile> upload({
    required String fileName,
    required Uint8List bytes,
    String? id,
  });

  /// Downloads the file with [fileId].
  ///
  /// Throws [DataNotFoundError] if it doesn't exist, or
  /// [DataPermissionError] if it isn't owned by the current user.
  Future<Uint8List> download(String fileId);

  /// Deletes the file with [fileId]. Throws [DataNotFoundError] if it
  /// doesn't exist, or [DataPermissionError] if it isn't owned by the
  /// current user.
  Future<void> delete(String fileId);
}
