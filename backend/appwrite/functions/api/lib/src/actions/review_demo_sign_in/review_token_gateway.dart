/// The Appwrite call `ReviewSignInService` needs once a submitted code
/// matches, behind an interface so that comparison logic can be unit-tested
/// with a fake — no live Appwrite instance required.
/// `AppwriteReviewTokenGateway` is the real implementation.
abstract class ReviewTokenGateway {
  /// Issues a fresh session token for [userId] (the allow-listed review
  /// demo account's own ID, from `REVIEW_DEMO_USER_ID` — never from the
  /// caller).
  Future<ReviewSessionToken> createTokenFor(String userId);
}

/// A freshly issued session token — enough for the caller to trade for a
/// real Appwrite session via `Account.createSession(userId, secret)`, the
/// same call this template's own email-OTP flow already ends with (see
/// `backend/appwrite/adapters`'s `AppwriteAuthService.verifyEmailCode`).
class ReviewSessionToken {
  /// Creates a token for [userId]/[secret].
  const ReviewSessionToken({required this.userId, required this.secret});

  /// The review demo account's user ID.
  final String userId;

  /// The one-time secret `Account.createSession` exchanges for a session.
  final String secret;
}
