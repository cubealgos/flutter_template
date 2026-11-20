import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

/// The Appwrite `Account`/`Functions` calls `AppwriteAuthService` needs,
/// behind an interface so its own logic (capability gating, session-stream
/// updates, error mapping) can be unit-tested with a fake — no live
/// Appwrite instance, and no Flutter platform bindings, required.
/// `AppwriteAccountGateway` is the real implementation.
///
/// Mirrors `backend/appwrite/functions/api`'s
/// `delete_account` action's `AccountDeletionGateway` /
/// `AppwriteAccountDeletionGateway` split — same
/// reasoning, applied to the client side.
abstract class AccountGateway {
  /// The currently logged-in user. Throws [AppwriteException] if there is
  /// no current session.
  Future<models.User> getCurrentUser();

  /// Requests an email OTP token for [userId]/[email] — see
  /// `AppwriteAuthService.requestEmailCode`'s dartdoc for what [userId]
  /// should be and the account-existence subtlety this call has.
  Future<models.Token> createEmailToken({
    required String userId,
    required String email,
  });

  /// Exchanges a token's [userId]/[secret] for a session — used both to
  /// verify an email code and (in tests) to skip real email delivery via
  /// an admin-issued token.
  Future<models.Session> createSessionFromToken({
    required String userId,
    required String secret,
  });

  /// Executes the `api` Function's `review_demo_sign_in` action with
  /// [code] and returns
  /// its JSON response body — backs
  /// `AppwriteAuthService.signInWithReviewCode`, the App Review demo
  /// account path. Throws [AppwriteException] (carrying the
  /// execution's own HTTP status — 401 for a wrong [code], the one case
  /// `signInWithReviewCode` maps back to `AuthInvalidCodeError` rather
  /// than a generic failure) for any non-2xx execution response.
  Future<String> executeReviewDemoSignInFunction(String code);

  /// Starts an interactive OAuth2 sign-in for [provider]. Launches a
  /// platform browser view (`flutter_web_auth_2`) — cannot run headless,
  /// so no integration test exercises this; see
  /// `AppwriteAuthService.signInWithOAuth`'s dartdoc.
  Future<void> createOAuth2Session(enums.OAuthProvider provider);

  /// Ends the current session (`'current'`).
  Future<void> deleteCurrentSession();

  /// Lists identities linked to the current account.
  Future<models.IdentityList> listIdentities();

  /// Unlinks the identity with [identityId].
  Future<void> deleteIdentity(String identityId);

  /// Executes the `api` Function's `delete_account` action as the current
  /// user and
  /// returns its JSON response body.
  Future<String> executeDeleteAccountFunction();

  /// Reads the current user's stored preferences — backs
  /// `AppwriteUserPreferences.getAll`.
  Future<models.Preferences> getPrefs();

  /// Replaces the current user's stored preferences with [prefs] in full,
  /// returning the updated user (Appwrite's own `Account.updatePrefs`
  /// return type — the updated preferences are `User.prefs`).
  ///
  /// Appwrite's own `Account.updatePrefs` always *replaces* the whole
  /// preferences object, never merges — `AppwriteUserPreferences.update`
  /// is what reads the current value via [getPrefs] and merges on top
  /// before calling this, so callers of the `UserPreferences` interface
  /// see merge semantics without this gateway method needing to know
  /// about it.
  Future<models.User> updatePrefs(Map<String, dynamic> prefs);
}
