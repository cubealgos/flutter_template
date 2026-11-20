import 'package:api/src/actions/review_demo_sign_in/review_sign_in_service.dart';
import 'package:test/test.dart';

import 'fakes/fake_review_token_gateway.dart';

void main() {
  test(
    'issues a token for the configured demo user on a matching code',
    () async {
      final gateway = FakeReviewTokenGateway();
      final service = ReviewSignInService(
        gateway: gateway,
        configuredCode: 'the-real-code',
        demoUserId: 'demo-user-1',
      );

      final token = await service.signIn('the-real-code');

      expect(token?.userId, 'demo-user-1');
      expect(gateway.requestedUserIds, <String>['demo-user-1']);
    },
  );

  test('returns null (never issues a token) for a mismatching code', () async {
    final gateway = FakeReviewTokenGateway();
    final service = ReviewSignInService(
      gateway: gateway,
      configuredCode: 'the-real-code',
      demoUserId: 'demo-user-1',
    );

    final token = await service.signIn('a-guess');

    expect(token, isNull);
    expect(gateway.requestedUserIds, isEmpty);
  });

  test('waits mismatchDelay before returning a mismatch result', () async {
    final gateway = FakeReviewTokenGateway();
    final service = ReviewSignInService(
      gateway: gateway,
      configuredCode: 'the-real-code',
      demoUserId: 'demo-user-1',
    );
    final stopwatch = Stopwatch()..start();

    await service.signIn('wrong');

    expect(stopwatch.elapsed, greaterThanOrEqualTo(mismatchDelay));
  });

  test('is inert for every user ID except the configured one', () async {
    final gateway = FakeReviewTokenGateway();
    final service = ReviewSignInService(
      gateway: gateway,
      configuredCode: 'the-real-code',
      demoUserId: 'the-one-allow-listed-user',
    );

    await service.signIn('the-real-code');

    expect(gateway.requestedUserIds, <String>['the-one-allow-listed-user']);
  });
}
