import 'package:api/src/actions/review_demo_sign_in/handle_review_demo_sign_in_request.dart';
import 'package:test/test.dart';

import 'fakes/fake_review_token_gateway.dart';

void main() {
  test('refuses with 500 when REVIEW_DEMO_CODE is not configured', () async {
    final response = await handleReviewDemoSignInRequest(
      submittedCode: 'anything',
      configuredCode: null,
      demoUserId: 'demo-user-1',
      gateway: FakeReviewTokenGateway(),
    );

    expect(response.statusCode, missingConfigurationStatusCode);
  });

  test('refuses with 500 when REVIEW_DEMO_USER_ID is not configured', () async {
    final response = await handleReviewDemoSignInRequest(
      submittedCode: 'anything',
      configuredCode: 'the-real-code',
      demoUserId: '',
      gateway: FakeReviewTokenGateway(),
    );

    expect(response.statusCode, missingConfigurationStatusCode);
  });

  test('refuses with 400 when the request has no code', () async {
    final response = await handleReviewDemoSignInRequest(
      submittedCode: null,
      configuredCode: 'the-real-code',
      demoUserId: 'demo-user-1',
      gateway: FakeReviewTokenGateway(),
    );

    expect(response.statusCode, invalidRequestStatusCode);
  });

  test('refuses with 401 on a wrong code, issuing no token', () async {
    final gateway = FakeReviewTokenGateway();

    final response = await handleReviewDemoSignInRequest(
      submittedCode: 'wrong',
      configuredCode: 'the-real-code',
      demoUserId: 'demo-user-1',
      gateway: gateway,
    );

    expect(response.statusCode, unauthorizedStatusCode);
    expect(gateway.requestedUserIds, isEmpty);
  });

  test('returns 200 with a userId/secret on the right code', () async {
    final response = await handleReviewDemoSignInRequest(
      submittedCode: 'the-real-code',
      configuredCode: 'the-real-code',
      demoUserId: 'demo-user-1',
      gateway: FakeReviewTokenGateway(),
    );

    expect(response.statusCode, okStatusCode);
    expect(response.body['userId'], 'demo-user-1');
    expect(response.body['secret'], isNotEmpty);
  });
}
