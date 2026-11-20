import 'package:api/src/actions/review_demo_sign_in/constant_time_equals.dart';
import 'package:api/src/actions/review_demo_sign_in/review_token_gateway.dart';

/// How long [ReviewSignInService.signIn] waits before returning a mismatch
/// result — a small, fixed delay independent of anything about the
/// submitted code (never scaled by how "close" a guess was, which would
/// itself leak information). Defense in depth alongside
/// [constantTimeEquals]; the primary defense against brute-forcing the
/// review code is Appwrite's own per-project/per-IP execution rate
/// limiting (configured at the Appwrite instance level, not reimplemented
/// here — see `backend/appwrite/README.md`).
const Duration mismatchDelay = Duration(milliseconds: 250);

/// Exchanges a submitted review code for a session token on one
/// allow-listed, admin-seeded demo account — this template's App Review
/// demo access path. Both [configuredCode] and
/// [demoUserId] come from this Function's own environment variables
/// (`REVIEW_DEMO_CODE`/`REVIEW_DEMO_USER_ID`, set by
/// `backend/appwrite/tool/bin/seed_review_demo_account.dart` — see `lib/main.dart`), not
/// from the request: the caller supplies only the code they're guessing,
/// never which account to sign into.
class ReviewSignInService {
  /// Creates a service comparing against [configuredCode], issuing a token
  /// for [demoUserId] through [gateway] on a match.
  const ReviewSignInService({
    required this.gateway,
    required this.configuredCode,
    required this.demoUserId,
  });

  /// The Appwrite call made once the submitted code matches.
  final ReviewTokenGateway gateway;

  /// The one code this Function accepts.
  final String configuredCode;

  /// The one account [gateway] ever issues a token for.
  final String demoUserId;

  /// Compares [submittedCode] against [configuredCode] and, on a match,
  /// returns a fresh session token for [demoUserId]. Returns null on a
  /// mismatch, after waiting [mismatchDelay] — never throws for "wrong
  /// code", only for a genuine [gateway] failure.
  Future<ReviewSessionToken?> signIn(String submittedCode) async {
    if (!constantTimeEquals(submittedCode, configuredCode)) {
      await Future<void>.delayed(mismatchDelay);

      return null;
    }

    return await gateway.createTokenFor(demoUserId);
  }
}
