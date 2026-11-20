/// Backend-agnostic authentication: the `AuthService` interface, its typed
/// `AuthError` hierarchy, and `FakeAuthService`, an in-memory
/// implementation for screens and tests.
///
/// `backend/appwrite/adapters`'s `AppwriteAuthService` is the template's
/// default real implementation. Split into one file per declared type
/// under `src/` (matching this workspace's `prefer_match_file_name`
/// lint) — this file just re-exports all of them, mirroring
/// `backend/appwrite/schema`'s barrel.
library;

export 'src/auth_capabilities.dart';
export 'src/auth_error.dart';
export 'src/auth_service.dart';
export 'src/auth_session.dart';
export 'src/email_code_request.dart';
export 'src/fake_auth_service.dart';
export 'src/linked_identity.dart';
export 'src/oauth_provider.dart';
