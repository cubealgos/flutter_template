import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/appwrite_data_error_mapping.dart';
import 'package:appwrite_adapters/src/current_appwrite_user_id.dart';
import 'package:data/data.dart';

/// The [StorageService] implementation backed by Appwrite's `Storage`
/// service.
///
/// One instance is scoped to one [bucketId]. Every uploaded file gets
/// per-file read/update/delete permissions restricted to the calling
/// user — see `AppwriteDocumentRepository`'s dartdoc for the same
/// reasoning (Appwrite must also have `fileSecurity` on and a table-level
/// grant for this to actually be enforced; this template's own
/// `bin/provision.dart` sets both for every bucket it creates).
class AppwriteStorageService implements StorageService {
  /// Creates a storage service for [bucketId].
  AppwriteStorageService(Client client, {required this.bucketId})
    : _storage = Storage(client),
      _account = Account(client);

  /// The bucket this service uploads to and downloads/deletes from.
  final String bucketId;

  final Storage _storage;
  final Account _account;

  @override
  Future<StoredFile> upload({
    required String fileName,
    required Uint8List bytes,
    String? id,
  }) async {
    final userId = await currentAppwriteUserId(_account);
    final ownerRole = Role.user(userId);

    try {
      final file = await _storage.createFile(
        bucketId: bucketId,
        fileId: id ?? ID.unique(),
        file: InputFile.fromBytes(bytes: bytes, filename: fileName),
        permissions: <String>[
          Permission.read(ownerRole),
          Permission.update(ownerRole),
          Permission.delete(ownerRole),
        ],
      );

      return StoredFile(
        id: file.$id,
        fileName: file.name,
        sizeBytes: file.sizeOriginal,
      );
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  @override
  Future<Uint8List> download(String fileId) async {
    try {
      return await _storage.getFileDownload(bucketId: bucketId, fileId: fileId);
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }

  @override
  Future<void> delete(String fileId) async {
    try {
      await _storage.deleteFile(bucketId: bucketId, fileId: fileId);
    } on AppwriteException catch (e) {
      throw mapAppwriteDataError(e);
    }
  }
}
