import 'package:appwrite_tool/src/review_demo_account.dart';
import 'package:test/test.dart';

import 'fakes/fake_review_demo_account_gateway.dart';

void main() {
  group('seedReviewDemoAccount creating', () {
    test('creates a new user with no password and configures the '
        'Function variables', () async {
      final gateway = FakeReviewDemoAccountGateway();

      final result = await seedReviewDemoAccount(
        gateway: gateway,
        email: 'reviewer@example.com',
        generateCode: () => 'generated-code',
      );

      expect(result.generatedCode, 'generated-code');
      expect(gateway.verifiedUserIds, <String>[result.userId]);
      expect(
        gateway.functionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoUserIdVariableKey,
        ),
        result.userId,
      );
      expect(
        gateway.functionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoCodeVariableKey,
        ),
        'generated-code',
      );
    });

    test('never touches an account for a different email', () async {
      final gateway = FakeReviewDemoAccountGateway()
        ..seedExisting(email: 'someone-else@example.com', userId: 'other-user');

      final result = await seedReviewDemoAccount(
        gateway: gateway,
        email: 'reviewer@example.com',
        generateCode: () => 'generated-code',
      );

      expect(result.userId, isNot('other-user'));
    });
  });

  group('seedReviewDemoAccount idempotency', () {
    test('is a no-op against an already-fully-configured account', () async {
      final gateway = FakeReviewDemoAccountGateway()
        ..seedExisting(email: 'reviewer@example.com', userId: 'existing-user')
        ..seedFunctionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoUserIdVariableKey,
          value: 'existing-user',
        )
        ..seedFunctionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoCodeVariableKey,
          value: 'existing-code',
        );

      final result = await seedReviewDemoAccount(
        gateway: gateway,
        email: 'reviewer@example.com',
        generateCode: () => 'unused',
      );

      expect(result.userId, 'existing-user');
      expect(result.generatedCode, isNull);
      // Never asked the gateway to verify anything - no account was
      // created, so there's nothing new to verify.
      expect(gateway.verifiedUserIds, isEmpty);
      expect(
        gateway.functionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoCodeVariableKey,
        ),
        'existing-code',
      );
    });

    test('fills in a missing code variable for an otherwise-configured '
        'account without regenerating the user', () async {
      final gateway = FakeReviewDemoAccountGateway()
        ..seedExisting(email: 'reviewer@example.com', userId: 'existing-user')
        ..seedFunctionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoUserIdVariableKey,
          value: 'existing-user',
        );

      final result = await seedReviewDemoAccount(
        gateway: gateway,
        email: 'reviewer@example.com',
        generateCode: () => 'freshly-generated-code',
      );

      expect(result.userId, 'existing-user');
      expect(result.generatedCode, 'freshly-generated-code');
    });
  });

  _blankCodeVariableTests();

  group('seedReviewDemoAccount rotation', () {
    test('rerunning with a different email updates REVIEW_DEMO_USER_ID to '
        'the new account, without touching the existing code', () async {
      final gateway = FakeReviewDemoAccountGateway()
        ..seedExisting(email: 'old-reviewer@example.com', userId: 'old-user')
        ..seedFunctionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoUserIdVariableKey,
          value: 'old-user',
        )
        ..seedFunctionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoCodeVariableKey,
          value: 'existing-code',
        );

      final result = await seedReviewDemoAccount(
        gateway: gateway,
        email: 'new-reviewer@example.com',
        generateCode: () => 'unused',
      );

      expect(result.userId, isNot('old-user'));
      expect(
        gateway.functionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoUserIdVariableKey,
        ),
        result.userId,
      );
      // The code is a secret and follows the opposite policy - never
      // overwritten by a rotation that only changed the target account.
      expect(result.generatedCode, isNull);
      expect(
        gateway.functionVariable(
          functionId: reviewDemoFunctionId,
          key: reviewDemoCodeVariableKey,
        ),
        'existing-code',
      );
    });
  });
}

/// A blank code variable counts as unconfigured.
void _blankCodeVariableTests() {
  group('seedReviewDemoAccount blank code variable', () {
    for (final blank in <String>['', '   ', '\n\t']) {
      test('writes a code into a blank (${blank.length} chars) variable '
          'instead of duplicating or skipping it', () async {
        final gateway = FakeReviewDemoAccountGateway()
          ..seedExisting(email: 'reviewer@example.com', userId: 'existing-user')
          ..seedFunctionVariable(
            functionId: reviewDemoFunctionId,
            key: reviewDemoUserIdVariableKey,
            value: '',
          )
          ..seedFunctionVariable(
            functionId: reviewDemoFunctionId,
            key: reviewDemoCodeVariableKey,
            value: blank,
          );

        final result = await seedReviewDemoAccount(
          gateway: gateway,
          email: 'reviewer@example.com',
          generateCode: () => 'fresh-code',
        );

        expect(result.generatedCode, 'fresh-code');
        expect(
          gateway.functionVariable(
            functionId: reviewDemoFunctionId,
            key: reviewDemoCodeVariableKey,
          ),
          'fresh-code',
        );
        expect(
          gateway.functionVariable(
            functionId: reviewDemoFunctionId,
            key: reviewDemoUserIdVariableKey,
          ),
          'existing-user',
        );
      });
    }

    _blankFilledOnceTest();
  });
}

void _blankFilledOnceTest() {
  test('a second run after a blank was filled is a no-op', () async {
    final gateway = FakeReviewDemoAccountGateway()
      ..seedFunctionVariable(
        functionId: reviewDemoFunctionId,
        key: reviewDemoCodeVariableKey,
        value: '',
      );
    await seedReviewDemoAccount(
      gateway: gateway,
      email: 'reviewer@example.com',
      generateCode: () => 'fresh-code',
    );

    final second = await seedReviewDemoAccount(
      gateway: gateway,
      email: 'reviewer@example.com',
      generateCode: () => 'must-not-be-used',
    );

    expect(second.generatedCode, isNull);
    expect(
      gateway.functionVariable(
        functionId: reviewDemoFunctionId,
        key: reviewDemoCodeVariableKey,
      ),
      'fresh-code',
    );
  });
}
