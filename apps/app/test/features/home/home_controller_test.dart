import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:app/features/home/home_controller.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import '../../support/settle.dart';
import 'home_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[
  MockSpec<NavigationService>(),
  MockSpec<DialogService>(),
])
void main() {
  group('HomeController', () {
    test('openSettings pushes the Settings hub', () {
      final navigation = MockNavigationService();
      HomeController(
        navigation,
        FakeAuthService(),
        MockDialogService(),
        FakeUserPreferences(),
        onboardingSteps: _steps(),
      ).openSettings();

      verify(navigation.push(const SettingsHubRoute().location)).called(1);
    });

    test('openOnboarding pushes the onboarding stepper', () {
      final navigation = MockNavigationService();
      HomeController(
        navigation,
        FakeAuthService(),
        MockDialogService(),
        FakeUserPreferences(),
        onboardingSteps: _steps(),
      ).openOnboarding();

      verify(navigation.push(const OnboardingRoute().location)).called(1);
    });

    test('signOut ends the session and returns to sign-in', () async {
      final navigation = MockNavigationService();
      final auth = FakeAuthService();
      await auth.signInWithPasskey();
      final controller = HomeController(
        navigation,
        auth,
        MockDialogService(),
        FakeUserPreferences(),
        onboardingSteps: _steps(),
      );

      await controller.signOut();

      expect(auth.currentSession, isNull);
      verify(navigation.go(const SignInRoute().location)).called(1);
    });
  });

  group('HomeController push permission pre-prompt', () {
    test('shows the push permission pre-prompt once, in context, on first '
        'arrival', () async {
      final dialogService = MockDialogService();
      final preferences = FakeUserPreferences();
      HomeController(
        MockNavigationService(),
        FakeAuthService(),
        dialogService,
        preferences,
        onboardingSteps: _steps(),
      ).init();

      await settle();

      verify(dialogService.show(any)).called(1);
      expect(
        (await preferences.getAll())[pushPermissionPromptShownPreferenceKey],
        isTrue,
      );
    });

    test('does not show the prompt again once already shown', () async {
      final dialogService = MockDialogService();
      final preferences = FakeUserPreferences();
      await preferences.update(<String, dynamic>{
        pushPermissionPromptShownPreferenceKey: true,
      });
      HomeController(
        MockNavigationService(),
        FakeAuthService(),
        dialogService,
        preferences,
        onboardingSteps: _steps(),
      ).init();

      await settle();

      verifyNever(dialogService.show(any));
    });
  });

  group('HomeController "Finish your setup" card visibility: loading', () {
    test('is hidden while the initial read is still in flight', () {
      final controller = HomeController(
        MockNavigationService(),
        FakeAuthService(),
        MockDialogService(),
        FakeUserPreferences(),
        onboardingSteps: _steps(),
      );

      expect(controller.showSetupCard, isFalse);
    });
  });

  group('HomeController "Finish your setup" card visibility: loaded', () {
    test('shows once loaded, listing every incomplete or skipped '
        'step', () async {
      final preferences = FakeUserPreferences();
      await preferences.update(<String, dynamic>{
        onboardingStepStatusPreferenceKey: <String, String>{
          'profile': 'completed',
          'preferences': 'skipped',
        },
      });
      final controller = HomeController(
        MockNavigationService(),
        FakeAuthService(),
        MockDialogService(),
        preferences,
        onboardingSteps: _steps(),
      )..init();
      await settle();

      expect(controller.showSetupCard, isTrue);
      expect(controller.model.completedStepCount, 1);
      expect(controller.model.totalStepCount, _steps().length);
      expect(controller.model.openSteps.map((step) => step.id), <String>[
        'preferences',
        'notifications',
      ]);
    });

    test('hides once every step is actually completed — a skipped step '
        'stays listed, not just addressed', () async {
      final preferences = FakeUserPreferences();
      await preferences.update(<String, dynamic>{
        onboardingStepStatusPreferenceKey: <String, String>{
          'profile': 'completed',
          'preferences': 'completed',
          'notifications': 'completed',
        },
      });
      final controller = HomeController(
        MockNavigationService(),
        FakeAuthService(),
        MockDialogService(),
        preferences,
        onboardingSteps: _steps(),
      )..init();
      await settle();

      expect(controller.showSetupCard, isFalse);
    });
  });

  group('HomeController "Finish your setup" card dismissal', () {
    test('dismissSetupCard hides the card for the rest of this '
        'session', () async {
      final preferences = FakeUserPreferences();
      final controller = HomeController(
        MockNavigationService(),
        FakeAuthService(),
        MockDialogService(),
        preferences,
        onboardingSteps: _steps(),
      )..init();
      await settle();

      expect(controller.showSetupCard, isTrue);

      controller.dismissSetupCard();

      expect(controller.showSetupCard, isFalse);
    });
  });
}

/// A minimal three-step registry stand-in — `HomeController` only ever
/// reads each step's `id`/`title`, never its `builder`.
List<OnboardingStep> _steps() {
  return <OnboardingStep>[
    OnboardingStep(
      id: 'profile',
      title: 'Profile',
      builder: (_, _) => const SizedBox.shrink(),
    ),
    OnboardingStep(
      id: 'preferences',
      title: 'Preferences',
      builder: (_, _) => const SizedBox.shrink(),
    ),
    OnboardingStep(
      id: 'notifications',
      title: 'Notifications',
      builder: (_, _) => const SizedBox.shrink(),
    ),
  ];
}
