/// Appwrite adapters for `core/contracts/auth`, `core/contracts/data` and
/// `core/contracts/teams`: `AppwriteAuthService`, `AppwriteDocumentRepository`,
/// `AppwriteStorageService`, `AppwriteUserPreferences`,
/// `AppwriteVersionPolicy` and `AppwriteTeamService` (a client of the
/// `team_admin` Function), backed by the `appwrite` client SDK.
///
/// Every adapter takes its Appwrite `Client` via constructor — DI (get_it
/// registration) happens in the app, not here. Split into
/// one file per declared type under `src/` (matching this workspace's
/// `prefer_match_file_name` lint) — this file just re-exports the public
/// ones, mirroring `backend/appwrite/schema`'s barrel. `AccountGateway` and
/// its default implementation are also exported, so an app (or a test) can
/// build an `AppwriteAuthService.withGateway` against its own fake.
library;

export 'src/account_gateway.dart';
export 'src/api_client.dart';
export 'src/appwrite_account_gateway.dart';
export 'src/appwrite_auth_error_mapping.dart';
export 'src/appwrite_auth_service.dart';
export 'src/appwrite_billing.dart';
export 'src/appwrite_data_error_mapping.dart';
export 'src/appwrite_document_permissions.dart';
export 'src/appwrite_document_repository.dart';
export 'src/appwrite_job_queue.dart';
export 'src/appwrite_query_mapping.dart';
export 'src/appwrite_storage_service.dart';
export 'src/appwrite_team_function_gateway.dart';
export 'src/appwrite_team_service.dart';
export 'src/appwrite_user_preferences.dart';
export 'src/appwrite_version_check.dart';
export 'src/appwrite_version_policy.dart';
export 'src/compare_dotted_versions.dart';
export 'src/team_function_gateway.dart';
