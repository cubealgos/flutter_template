import 'dart:typed_data';

import 'package:data/src/data_error.dart';
import 'package:data/src/storage_service.dart';
import 'package:data/src/stored_file.dart';

/// An in-memory [StorageService] for screens and tests — see
/// `FakeDocumentRepository`'s dartdoc for the [authenticated] flag.
class FakeStorageService implements StorageService {
  /// Creates an empty in-memory bucket.
  FakeStorageService({this.authenticated = true});

  /// Whether calls should succeed as a signed-in user.
  bool authenticated;

  final Map<String, StoredFile> _metadataById = <String, StoredFile>{};
  final Map<String, Uint8List> _bytesById = <String, Uint8List>{};
  int _idSequence = 0;

  @override
  Future<StoredFile> upload({
    required String fileName,
    required Uint8List bytes,
    String? id,
  }) async {
    _requireAuthenticated();
    final resolvedId = id ?? 'fake-file-${_idSequence++}';
    final stored = StoredFile(
      id: resolvedId,
      fileName: fileName,
      sizeBytes: bytes.length,
    );
    _metadataById[resolvedId] = stored;
    _bytesById[resolvedId] = Uint8List.fromList(bytes);

    return stored;
  }

  @override
  Future<Uint8List> download(String fileId) async {
    _requireAuthenticated();
    final bytes = _bytesById[fileId];
    if (bytes == null) {
      throw DataNotFoundError('No file with id "$fileId".');
    }

    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(String fileId) async {
    _requireAuthenticated();
    if (!_metadataById.containsKey(fileId)) {
      throw DataNotFoundError('No file with id "$fileId".');
    }
    _metadataById.remove(fileId);
    _bytesById.remove(fileId);
  }

  void _requireAuthenticated() {
    if (!authenticated) {
      throw const DataUnauthenticatedError('No current user.');
    }
  }
}
