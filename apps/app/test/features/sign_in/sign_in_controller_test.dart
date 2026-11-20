import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/sign_in/sign_in_controller.dart';
import 'package:app/features/sign_in/sign_in_error.dart';
import 'package:app/features/sign_in/sign_in_step.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import 'sign_in_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<NavigationService>()])
void main() {
  group('SignInController capability visibility', () {
    test('passkey button hidden when the switch is off even if the '
        'backend supports it', () {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      );

      expect(controller.showPasskeyButton, isFalse);
    });

    test('passkey button hidden when the backend does not support it, '
        'even with the switch on', () {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(capabilities: const AuthCapabilities()),
        const AppConfig(passkeys: true),
        FakeUserPreferences(),
      );

      expect(controller.showPasskeyButton, isFalse);
    });

    test(
      'passkey button shown when both the switch and capability allow it',
      () {
        final controller = SignInController(
          MockNavigationService(),
          FakeAuthService(
            capabilities: const AuthCapabilities(supportsPasskeys: true),
          ),
          const AppConfig(passkeys: true),
          FakeUserPreferences(),
        );

        expect(controller.showPasskeyButton, isTrue);
      },
    );

    test('reviewer button only shows when reviewDemoEnabled is set', () {
      final withoutDemo = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      );
      final withDemo = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(reviewDemoEnabled: true),
        FakeUserPreferences(),
      );

      expect(withoutDemo.showReviewerButton, isFalse);
      expect(withDemo.showReviewerButton, isTrue);
    });
  });

  group('SignInController email code flow', () {
    test('never reveals whether the account already existed — always moves '
        'to codeEntry', () async {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      )..emailController.text = 'new@example.com';

      await controller.requestCode();

      expect(controller.model.step, SignInStep.codeEntry);
      expect(controller.model.error, isNull);
    });

    test('verifying the fixed fake code completes sign-in and navigates '
        'to onboarding', () async {
      final navigation = MockNavigationService();
      final controller = SignInController(
        navigation,
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      )..emailController.text = 'a@b.c';
      await controller.requestCode();
      controller.codeController.text = FakeAuthService.fixedEmailCode;

      await controller.verifyCode();

      verify(navigation.go(const OnboardingRoute().location)).called(1);
    });
  });

  group('SignInController email code verification errors', () {
    test('a wrong code sets SignInError.invalidCode and stays put', () async {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      )..emailController.text = 'a@b.c';
      await controller.requestCode();
      controller.codeController.text = 'wrong-code';

      await controller.verifyCode();

      expect(controller.model.error, SignInError.invalidCode);
      expect(controller.model.step, SignInStep.codeEntry);
    });

    test(
      'changeEmail returns to the email step and clears the code field',
      () async {
        final controller = SignInController(
          MockNavigationService(),
          FakeAuthService(),
          const AppConfig(),
          FakeUserPreferences(),
        )..emailController.text = 'a@b.c';
        await controller.requestCode();
        controller.codeController.text = '123456';

        controller.changeEmail();

        expect(controller.model.step, SignInStep.emailEntry);
        expect(controller.codeController.text, isEmpty);
      },
    );
  });

  group('SignInController continueAsReviewer', () {
    test('moves to the review code step when enabled', () {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(reviewDemoEnabled: true),
        FakeUserPreferences(),
      )..continueAsReviewer();

      expect(controller.model.step, SignInStep.reviewCode);
    });

    test('is a no-op when the demo shortcut is not enabled', () {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      )..continueAsReviewer();

      expect(controller.model.step, SignInStep.emailEntry);
    });
  });

  group('SignInController submitReviewCode', () {
    test('signs in and navigates on with the right review code', () async {
      final navigation = MockNavigationService();
      final controller =
          SignInController(
              navigation,
              FakeAuthService(
                reviewDemoCode: FakeAuthService.fixedReviewDemoCode,
              ),
              const AppConfig(reviewDemoEnabled: true),
              FakeUserPreferences(),
            )
            ..continueAsReviewer()
            ..reviewCodeController.text = FakeAuthService.fixedReviewDemoCode;

      await controller.submitReviewCode();

      verify(navigation.go(const OnboardingRoute().location)).called(1);
    });

    test('a wrong code sets SignInError.invalidCode and stays on the '
        'review code step', () async {
      final controller =
          SignInController(
              MockNavigationService(),
              FakeAuthService(
                reviewDemoCode: FakeAuthService.fixedReviewDemoCode,
              ),
              const AppConfig(reviewDemoEnabled: true),
              FakeUserPreferences(),
            )
            ..continueAsReviewer()
            ..reviewCodeController.text = 'wrong-code';

      await controller.submitReviewCode();

      expect(controller.model.error, SignInError.invalidCode);
      expect(controller.model.step, SignInStep.reviewCode);
    });

    test('is a no-op when the demo shortcut is not enabled, even with a '
        'code entered', () async {
      final controller = SignInController(
        MockNavigationService(),
        FakeAuthService(reviewDemoCode: FakeAuthService.fixedReviewDemoCode),
        const AppConfig(),
        FakeUserPreferences(),
      )..reviewCodeController.text = FakeAuthService.fixedReviewDemoCode;

      await controller.submitReviewCode();

      expect(controller.model.submitting, isFalse);
      expect(controller.model.step, SignInStep.emailEntry);
    });
  });
}
