/// The Appwrite `Users`/`Functions` operations `seedReviewDemoAccount`
/// needs, behind an interface so its idempotency logic can be
/// unit-tested with a fake — no live Appwrite instance required.
/// `DartAppwriteReviewDemoAccountGateway` is the real implementation.
/// Mirrors `AppwriteAdmin`/`Provisioner`'s split (see `appwrite_admin.dart`),
/// applied to the one user account and one Function's variables this tool
/// ever manages.
abstract class ReviewDemoAccountGateway {
  /// Returns the ID of the existing user registered for [email], or null if
  /// none exists yet.
  Future<String?> findUserIdByEmail(String email);

  /// Creates a new user with [email] and no password (no
  /// account this template creates is ever given a password — see
  /// `Provisioner.unusedAuthMethods`'s dartdoc for why) and returns its ID.
  Future<String> createUser({required String email});

  /// Marks the user's email as verified. Not required for the sign-in path
  /// to work, but keeps the seeded account from looking incomplete in the
  /// Appwrite console.
  Future<void> verifyEmail(String userId);

  /// Returns true if function [functionId] has a variable named [key]
  /// with a non-blank value (not empty, not whitespace-only). A variable
  /// that is missing **or blank** counts as unconfigured: `deploy.dart`
  /// creates `review_demo_sign_in`'s variables with empty values, so mere
  /// existence says nothing.
  Future<bool> functionVariableHasValue({
    required String functionId,
    required String key,
  });

  /// Sets function [functionId]'s variable [key] to [value] — creating it
  /// if it doesn't exist yet, **updating it in place if it does** (unlike
  /// `AppwriteAdmin.createFunctionVariable`, which only ever creates: this
  /// method backs `seedReviewDemoAccount`'s "keep the user-ID variable in
  /// sync" policy, which needs a real upsert — see that function's
  /// dartdoc).
  Future<void> setFunctionVariable({
    required String functionId,
    required String key,
    required String value,
  });
}
