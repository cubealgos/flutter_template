import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import '../../support/settle.dart';
import 'onboarding_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<NavigationService>()])
void main() {
  group('OnboardingController step progression: next/skip', () {
    test('resumes at the first step when nothing is persisted', () async {
      final navigation = MockNavigationService();
      final controller = OnboardingController(
        navigation,
        FakeUserPreferences(),
        steps: _threeSteps(),
      )..init();
      await settle();

      expect(controller.model.currentStepIndex, 0);
      expect(controller.model.resuming, isFalse);
      expect(controller.isFirstStep, isTrue);
      verifyNever(navigation.go(any));
    });

    test('next marks the current step completed and advances', () async {
      final controller = OnboardingController(
        MockNavigationService(),
        FakeUserPreferences(),
        steps: _threeSteps(),
      )..init();
      await settle();

      await controller.next();

      expect(controller.model.currentStepIndex, 1);
      expect(
        controller.model.stepStatus['profile'],
        OnboardingStepStatus.completed,
      );
    });

    test('skip marks the current step skipped and advances — only where '
        'the step allows it', () async {
      final controller = OnboardingController(
        MockNavigationService(),
        FakeUserPreferences(),
        steps: _threeSteps(),
      )..init();
      await settle();

      await controller.skip();

      expect(controller.model.currentStepIndex, 1);
      expect(
        controller.model.stepStatus['profile'],
        OnboardingStepStatus.skipped,
      );
    });
  });

  group('OnboardingController step progression: back/finish', () {
    test('back returns to the previous step; a no-op on the first '
        'step', () async {
      final controller = OnboardingController(
        MockNavigationService(),
        FakeUserPreferences(),
        steps: _threeSteps(),
      )..init();
      await settle();

      controller.back();
      expect(controller.model.currentStepIndex, 0);

      await controller.next();
      expect(controller.model.currentStepIndex, 1);

      controller.back();
      expect(controller.model.currentStepIndex, 0);
    });

    test('finishing the last step marks onboarding completed and '
        'navigates to Home', () async {
      final navigation = MockNavigationService();
      final preferences = FakeUserPreferences();
      final controller = OnboardingController(
        navigation,
        preferences,
        steps: _threeSteps(),
      )..init();
      await settle();

      await controller.next();
      await controller.next();
      await controller.next();

      verify(navigation.go(const HomeRoute().location)).called(1);
      expect(
        (await preferences.getAll())[onboardingCompletedPreferenceKey],
        isTrue,
      );
    });
  });

  group('OnboardingController persistence and resume: resuming', () {
    test('resumes at the first open step from persisted progress', () async {
      final preferences = FakeUserPreferences();
      await preferences.update(<String, dynamic>{
        onboardingStepStatusPreferenceKey: <String, String>{
          'profile': 'completed',
        },
      });
      final controller = OnboardingController(
        MockNavigationService(),
        preferences,
        steps: _threeSteps(),
      )..init();
      await settle();

      expect(controller.model.currentStepIndex, 1);
      expect(
        controller.model.stepStatus['profile'],
        OnboardingStepStatus.completed,
      );
    });

    test('a fully-addressed persisted state resumes straight to '
        'Home', () async {
      final navigation = MockNavigationService();
      final preferences = FakeUserPreferences();
      await preferences.update(<String, dynamic>{
        onboardingStepStatusPreferenceKey: <String, String>{
          'profile': 'completed',
          'preferences': 'skipped',
          'notifications': 'completed',
        },
      });
      OnboardingController(
        navigation,
        preferences,
        steps: _threeSteps(),
      ).init();
      await settle();

      verify(navigation.go(const HomeRoute().location)).called(1);
      expect(
        (await preferences.getAll())[onboardingCompletedPreferenceKey],
        isTrue,
      );
    });
  });

  group('OnboardingController persistence and resume: answers', () {
    test('updateAnswer persists immediately and a later resume reloads '
        'it', () async {
      final preferences = FakeUserPreferences();
      final controller = OnboardingController(
        MockNavigationService(),
        preferences,
        steps: _threeSteps(),
      )..init();
      await settle();

      controller.updateAnswer('profile', 'Ada');
      await settle();

      expect(controller.model.answers['profile'], 'Ada');
      expect(
        (await preferences.getAll())[onboardingAnswersPreferenceKey],
        <String, dynamic>{'profile': 'Ada'},
      );

      final resumed = OnboardingController(
        MockNavigationService(),
        preferences,
        steps: _threeSteps(),
      )..init();
      await settle();

      expect(resumed.model.answers['profile'], 'Ada');
    });

    test('entering a step records its defaultAnswer once, never over a '
        'real answer', () async {
      final preferences = FakeUserPreferences();
      final controller = OnboardingController(
        MockNavigationService(),
        preferences,
        steps: _stepsWithDefault(),
      )..init();
      await settle();

      await controller.next();
      await settle();

      expect(controller.model.answers['preferences'], 'personal');
      expect(
        (await preferences.getAll())[onboardingAnswersPreferenceKey],
        <String, dynamic>{'preferences': 'personal'},
      );

      controller
        ..updateAnswer('preferences', 'work')
        ..back();
      await controller.next();

      expect(controller.model.answers['preferences'], 'work');
    });
  });

  group('OnboardingController per-app extensibility', () {
    test('a custom, differently-sized step list works generically — '
        'proving the per-app extensibility point', () async {
      final navigation = MockNavigationService();
      final controller = OnboardingController(
        navigation,
        FakeUserPreferences(),
        steps: <OnboardingStep>[
          OnboardingStep(
            id: 'only-step',
            title: 'Only step',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      )..init();
      await settle();

      expect(controller.isFirstStep, isTrue);
      expect(controller.isLastStep, isTrue);

      await controller.next();

      verify(navigation.go(const HomeRoute().location)).called(1);
    });

    test("a step's onFinished side effect runs once it is finished", () async {
      var sideEffectRan = false;
      final controller = OnboardingController(
        MockNavigationService(),
        FakeUserPreferences(),
        steps: <OnboardingStep>[
          OnboardingStep(
            id: 'only-step',
            title: 'Only step',
            skip: OnboardingSkipAffordance.bottomButton,
            builder: (_, _) => const SizedBox.shrink(),
            onFinished: (_) async {
              sideEffectRan = true;
            },
          ),
        ],
      )..init();
      await settle();

      await controller.skip();

      expect(sideEffectRan, isTrue);
    });
  });
}

/// The template's default three step ids/skip affordances, with a
/// no-op renderer — enough for controller-level progression tests, which
/// never build a widget tree.
List<OnboardingStep> _threeSteps() {
  return <OnboardingStep>[
    OnboardingStep(
      id: 'profile',
      title: 'Profile',
      builder: (_, _) => const SizedBox.shrink(),
    ),
    OnboardingStep(
      id: 'preferences',
      title: 'Preferences',
      skip: OnboardingSkipAffordance.topLink,
      builder: (_, _) => const SizedBox.shrink(),
    ),
    OnboardingStep(
      id: 'notifications',
      title: 'Notifications',
      skip: OnboardingSkipAffordance.bottomButton,
      builder: (_, _) => const SizedBox.shrink(),
    ),
  ];
}

/// Two steps; the second pre-selects `personal` as its default answer.
List<OnboardingStep> _stepsWithDefault() {
  return <OnboardingStep>[
    OnboardingStep(
      id: 'profile',
      title: 'Profile',
      builder: (_, _) => const SizedBox.shrink(),
    ),
    OnboardingStep(
      id: 'preferences',
      title: 'Preferences',
      defaultAnswer: 'personal',
      builder: (_, _) => const SizedBox.shrink(),
    ),
  ];
}
