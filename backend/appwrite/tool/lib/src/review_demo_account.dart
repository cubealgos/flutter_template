import 'dart:math';

import 'package:appwrite_tool/src/review_demo_account_gateway.dart';

/// The ID of the Function whose variables hold the demo account's settings:
/// the `api` router, whose `review_demo_sign_in` action reads them — see `backend/appwrite/schema`'s `templateSchema`.
const String reviewDemoFunctionId = 'api';

/// The function variable holding the allow-listed demo account's user ID
/// — see the `review_demo_sign_in` action's own dartdoc for why this lives in a
/// function variable, never the request.
const String reviewDemoUserIdVariableKey = 'REVIEW_DEMO_USER_ID';

/// The function variable holding the shared review code.
const String reviewDemoCodeVariableKey = 'REVIEW_DEMO_CODE';

/// Characters [generateReviewDemoCode] draws from — letters, digits, and a few
/// symbols: enough entropy for a real credential (this now grants a real
/// session on the real backend, via `review_demo_sign_in`), while staying easy
/// to copy out of `.env.local` (or retype by hand from the Appwrite console)
/// into a store review-notes field. Excludes visually ambiguous characters
/// (`0`/`O`, `1`/`l`/`I`).
const String reviewDemoCodeAlphabet =
    r'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*';

/// How many characters [generateReviewDemoCode] produces.
const int reviewDemoCodeLength = 24;

/// Generates a random review code for a newly configured
/// `review_demo_sign_in` deployment. `Random.secure()`, not the default
/// `Random()` — this becomes a real credential, not a test fixture.
String generateReviewDemoCode() {
  final random = Random.secure();

  return List<String>.generate(
    reviewDemoCodeLength,
    (_) =>
        reviewDemoCodeAlphabet[random.nextInt(reviewDemoCodeAlphabet.length)],
  ).join();
}

/// Idempotently seeds the App Review demo account the store review needs: a
/// real Appwrite user with no password (see
/// [ReviewDemoAccountGateway.createUser]'s dartdoc for why), plus the
/// `review_demo_sign_in` Function's
/// [reviewDemoUserIdVariableKey]/[reviewDemoCodeVariableKey] variables pointing
/// at it. Never touches any other account: [gateway] is asked to look [email]
/// up first, and this only ever creates a new user when [email] doesn't already
/// resolve to one — safe to call on every deploy, the same way
/// `bin/provision.dart` is.
///
/// [reviewDemoUserIdVariableKey] is **kept in sync with [email]'s
/// resolved user on every call** — not a secret, just which account the
/// Function targets, so rerunning this for a *different* [email] (rotating
/// which account is the demo one) actually takes effect, rather than
/// silently creating an orphaned user while the Function keeps pointing at
/// whichever account it was first configured for.
/// [reviewDemoCodeVariableKey] is the one genuine secret here and follows
/// the opposite policy — created once, never overwritten by a later call
/// — a rotation that also wants a new code needs the old
/// `REVIEW_DEMO_CODE` function variable removed or blanked by hand first
/// (Appwrite console, or `dart_appwrite`'s `Functions.deleteVariable`)
/// before rerunning this script. A *blank* variable counts as unconfigured
/// and gets a fresh code.
///
/// With [rotate] true the code is the exception to that rule: a fresh code
/// is always generated and upserted (no duplicate variable), invalidating
/// the old one — the only way to replace a blank *secret* variable on
/// Appwrite Cloud, whose value the API hides.
///
/// The returned [ReviewDemoAccountResult.generatedCode] is set only when
/// this call actually generated a fresh code (the function variable didn't
/// exist yet). `bin/seed_review_demo_account.dart` is the only caller that
/// ever sees it, and only to write it straight to the shared `.env.local`
/// — never to print it (see that script's own doc comment).
Future<ReviewDemoAccountResult> seedReviewDemoAccount({
  required ReviewDemoAccountGateway gateway,
  required String email,
  String Function() generateCode = generateReviewDemoCode,
  bool rotate = false,
}) async {
  final existingUserId = await gateway.findUserIdByEmail(email);
  final userId = existingUserId ?? await gateway.createUser(email: email);
  if (existingUserId == null) {
    await gateway.verifyEmail(userId);
  }

  // Always synced to `userId`, not create-if-missing: see this function's
  // own dartdoc for why the user-ID variable and the code variable follow
  // opposite overwrite policies.
  await gateway.setFunctionVariable(
    functionId: reviewDemoFunctionId,
    key: reviewDemoUserIdVariableKey,
    value: userId,
  );
  final generatedCode = await _ensureCodeVariable(
    gateway,
    generateCode,
    rotate: rotate,
  );

  return ReviewDemoAccountResult(userId: userId, generatedCode: generatedCode);
}

/// Sets [reviewDemoCodeVariableKey] to a freshly generated code, but only
/// if it isn't already set to a non-blank value — returns the generated
/// code, or null if a real value already exists (nothing was generated or
/// written). A missing variable is created; a blank one (what `deploy.dart`
/// leaves behind) is updated in place by
/// [ReviewDemoAccountGateway.setFunctionVariable]'s upsert.
Future<String?> _ensureCodeVariable(
  ReviewDemoAccountGateway gateway,
  String Function() generateCode, {
  required bool rotate,
}) async {
  final configured =
      !rotate &&
      await gateway.functionVariableHasValue(
        functionId: reviewDemoFunctionId,
        key: reviewDemoCodeVariableKey,
      );
  if (configured) return null;

  final code = generateCode();
  await gateway.setFunctionVariable(
    functionId: reviewDemoFunctionId,
    key: reviewDemoCodeVariableKey,
    value: code,
  );

  return code;
}

/// What [seedReviewDemoAccount] did.
///
// This file is named for the top-level `seedReviewDemoAccount` orchestrator
// function it exports, not this result class - same convention as
// `core/design/ui`'s `button.dart`/`text_field.dart` (see either's own
// identical ignore).
// ignore: solid_lints/prefer_match_file_name
class ReviewDemoAccountResult {
  /// Creates a result. [generatedCode] is set only when this call actually
  /// generated a fresh review code.
  const ReviewDemoAccountResult({required this.userId, this.generatedCode});

  /// The account's Appwrite user ID, either way.
  final String userId;

  /// The newly generated review code — set only when this call generated
  /// one (the `REVIEW_DEMO_CODE` function variable didn't exist yet).
  /// Never logged or printed; the one caller that receives it
  /// (`bin/seed_review_demo_account.dart`) writes it straight to the
  /// shared `.env.local` and never echoes the value itself.
  final String? generatedCode;
}
