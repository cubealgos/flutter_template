import 'package:api/src/actions/review_demo_sign_in/review_sign_in_service.dart';
import 'package:api/src/actions/review_demo_sign_in/review_token_gateway.dart';
import 'package:api/src/function_response.dart';

/// The HTTP status returned when `REVIEW_DEMO_CODE`/`REVIEW_DEMO_USER_ID`
/// aren't set — this Function was deployed but never seeded (see
/// `backend/appwrite/tool/bin/seed_review_demo_account.dart`).
const int missingConfigurationStatusCode = 500;

/// The HTTP status returned when the request body has no `code`.
const int invalidRequestStatusCode = 400;

/// The HTTP status returned when the submitted code doesn't match —
/// generic on purpose: this Function never reveals *why* a code was
/// rejected (missing vs. wrong).
const int unauthorizedStatusCode = 401;

/// The HTTP status returned on a successful code exchange.
const int okStatusCode = 200;

/// Builds this Function's response: refuses if
/// `REVIEW_DEMO_CODE`/`REVIEW_DEMO_USER_ID` aren't configured, refuses if
/// the request has no `code`, otherwise compares [submittedCode] against
/// [configuredCode] (via [ReviewSignInService], which owns the
/// constant-time comparison and fixed mismatch delay) and returns a fresh
/// session token for [demoUserId] on a match.
///
/// Kept independent of the Appwrite runtime's own untyped `context` (see
/// `lib/main.dart`) so it is directly unit-testable. Never throws for a
/// wrong or missing code — only a genuine [gateway] failure (a real
/// Appwrite error creating the token) propagates, for `main.dart`'s own
/// try/catch to turn into a 500.
Future<FunctionResponse> handleReviewDemoSignInRequest({
  required String? submittedCode,
  required String? configuredCode,
  required String? demoUserId,
  required ReviewTokenGateway gateway,
}) async {
  // Direct `== null || .isEmpty` checks (not routed through a shared
  // helper predicate) so the analyzer can promote each parameter to a
  // non-nullable `String` past its own early return below - a helper
  // function call can't be promoted from, which would otherwise need a
  // `!` at every later use.
  if (configuredCode == null || configuredCode.isEmpty) {
    return const FunctionResponse(
      body: <String, dynamic>{
        'error':
            'review_demo_sign_in is not configured - run '
            'bin/seed_review_demo_account.dart.',
      },
      statusCode: missingConfigurationStatusCode,
    );
  }
  if (demoUserId == null || demoUserId.isEmpty) {
    return const FunctionResponse(
      body: <String, dynamic>{
        'error':
            'review_demo_sign_in is not configured - run '
            'bin/seed_review_demo_account.dart.',
      },
      statusCode: missingConfigurationStatusCode,
    );
  }
  if (submittedCode == null || submittedCode.isEmpty) {
    return const FunctionResponse(
      body: <String, dynamic>{'error': 'Missing "code" in the request body.'},
      statusCode: invalidRequestStatusCode,
    );
  }

  final service = ReviewSignInService(
    gateway: gateway,
    configuredCode: configuredCode,
    demoUserId: demoUserId,
  );
  final token = await service.signIn(submittedCode);
  if (token == null) {
    return const FunctionResponse(
      body: <String, dynamic>{'error': 'Invalid review code.'},
      statusCode: unauthorizedStatusCode,
    );
  }

  return FunctionResponse(
    body: <String, dynamic>{'userId': token.userId, 'secret': token.secret},
    statusCode: okStatusCode,
  );
}
