import 'package:api/src/action_context.dart';
import 'package:api/src/actions/review_demo_sign_in/appwrite_review_token_gateway.dart';
import 'package:api/src/actions/review_demo_sign_in/handle_review_demo_sign_in_request.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';

/// The `review_demo_sign_in` action: exchanges the shared
/// review code in the body's `code` field for a session token on the one
/// allow-listed demo account.
///
/// Callable with no session - a store reviewer has none - so
/// [requiresUser] is false. It reads the Function's `REVIEW_DEMO_CODE` and
/// `REVIEW_DEMO_USER_ID` variables, set by
/// `backend/appwrite/tool/bin/seed_review_demo_account.dart` on the `api`
/// Function.
class ReviewDemoSignInAction implements ApiAction {
  /// Creates the action.
  const ReviewDemoSignInAction();

  @override
  String get name => 'review_demo_sign_in';

  @override
  bool get requiresUser => false;

  /// Only what `Users.createToken` needs.
  @override
  Set<String> get scopes => const <String>{'users.read', 'users.write'};

  @override
  String get failureMessage => 'Review sign-in failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final code = context.body['code'];

    return handleReviewDemoSignInRequest(
      submittedCode: code is String ? code : null,
      configuredCode: context.environment['REVIEW_DEMO_CODE'],
      demoUserId: context.environment['REVIEW_DEMO_USER_ID'],
      gateway: AppwriteReviewTokenGateway(context.client),
    );
  }
}
