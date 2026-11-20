import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/appwrite_data_error_mapping.dart';

/// Returns the current session's user ID via [account], mapping a missing
/// session through [mapAppwriteDataError] (a `DataUnauthenticatedError`).
///
/// Shared by `AppwriteDocumentRepository` and `AppwriteStorageService` —
/// both need the calling user's ID to scope what they write.
Future<String> currentAppwriteUserId(Account account) async {
  try {
    final user = await account.get();

    return user.$id;
  } on AppwriteException catch (e) {
    throw mapAppwriteDataError(e, contextMessage: 'No current user.');
  }
}
