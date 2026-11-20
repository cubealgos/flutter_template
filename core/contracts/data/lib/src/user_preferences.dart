import 'package:data/src/data_error.dart';

/// Small per-user key/value preferences, backend-agnostic.
///
/// Backs the plan's "Default screens" consent choice (stored per user,
/// withdrawable in Settings → Privacy) and the onboarding checklist's
/// dismissed/completed state — both are "which keys are set", not
/// documents worth a whole `DocumentRepository` collection.
/// `backend/appwrite/adapters`'s `AppwriteUserPreferences` is the
/// template's default real implementation, backed by Appwrite's
/// `Account.updatePrefs`/`Account.getPrefs`; `FakeUserPreferences` is an
/// in-memory one for screens and tests.
abstract class UserPreferences {
  /// Reads every stored preference for the current user.
  ///
  /// Throws [DataUnauthenticatedError] if there is no current user.
  Future<Map<String, dynamic>> getAll();

  /// Merges [changes] into the current user's stored preferences —
  /// existing keys not present in [changes] are left untouched, and a
  /// key set to `null` in [changes] is removed.
  ///
  /// Throws [DataUnauthenticatedError] if there is no current user.
  Future<void> update(Map<String, dynamic> changes);
}
