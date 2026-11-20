/// Backend-agnostic data access: `DocumentRepository`, `StorageService`,
/// `UserPreferences`, `VersionPolicy`, the `DataQuery`/`DataFilter` query
/// shape, the typed `DataError` hierarchy, and in-memory fakes of every
/// interface for screens and tests.
///
/// `backend/appwrite/adapters`'s `AppwriteDocumentRepository`,
/// `AppwriteStorageService`, `AppwriteUserPreferences` and
/// `AppwriteVersionPolicy` are the template's default real
/// implementations. Split into one file per declared type under `src/`
/// (matching this workspace's `prefer_match_file_name` lint) — this file
/// just re-exports all of them, mirroring `backend/appwrite/schema`'s
/// barrel.
library;

export 'src/data_error.dart';
export 'src/data_filter.dart';
export 'src/data_query.dart';
export 'src/document.dart';
export 'src/document_repository.dart';
export 'src/document_scope.dart';
export 'src/fake_document_repository.dart';
export 'src/fake_storage_service.dart';
export 'src/fake_user_preferences.dart';
export 'src/fake_version_policy.dart';
export 'src/storage_service.dart';
export 'src/stored_file.dart';
export 'src/user_preferences.dart';
export 'src/version_check_result.dart';
export 'src/version_policy.dart';
