import 'package:api/src/action_context.dart';
import 'package:api/src/actions/review_demo_sign_in/handle_review_demo_sign_in_request.dart';
import 'package:api/src/actions/review_demo_sign_in/review_demo_sign_in_action.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:test/test.dart';

ActionContext _context({
  Map<String, dynamic> body = const <String, dynamic>{},
  Map<String, String> environment = const <String, String>{},
}) => ActionContext(
  callerUserId: null,
  body: body,
  environment: environment,
  client: Client(),
);

void main() {
  const action = ReviewDemoSignInAction();

  test('is callable with no session and needs only user scopes', () {
    expect(action.requiresUser, isFalse);
    expect(action.scopes, <String>{'users.read', 'users.write'});
  });

  test('refuses an unconfigured deployment before touching Appwrite', () async {
    final response = await action.run(
      _context(body: <String, dynamic>{'code': 'x'}),
    );

    expect(response.statusCode, missingConfigurationStatusCode);
  });

  test('refuses a body without a string code', () async {
    final response = await action.run(
      _context(
        body: <String, dynamic>{'code': 7},
        environment: <String, String>{
          'REVIEW_DEMO_CODE': 'c',
          'REVIEW_DEMO_USER_ID': 'u',
        },
      ),
    );

    expect(response.statusCode, invalidRequestStatusCode);
  });
}
