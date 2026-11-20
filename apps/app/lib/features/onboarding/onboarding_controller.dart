import 'dart:async';

import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:app/features/onboarding/onboarding_model.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:data/data.dart';
import 'package:mvc/mvc.dart';

/// Drives `OnboardingView`: a profile-setup stepper over [steps] (Profile →
/// Preferences → Notifications, by default — see `OnboardingStepRegistry`
/// for how a clone changes the step list), stored per user through
/// `UserPreferences` so it resumes at the first incomplete step — never a
/// carousel/tutorial (NN/g's controlled study found tutorials make tasks
/// feel harder; see the plan's "Default screens" section).
class OnboardingController extends ViewController<OnboardingModel> {
  /// Creates the controller for [steps] — the per-app, ordered step list
  /// (see `OnboardingStepRegistry`), fixed for this controller's lifetime.
  OnboardingController(
    this._navigation,
    this._preferences, {
    required this.steps,
  }) : assert(steps.isNotEmpty, 'OnboardingStepRegistry must not be empty.'),
       super(const OnboardingModel());

  final NavigationService _navigation;
  final UserPreferences _preferences;

  /// The ordered steps this stepper walks through — see
  /// [OnboardingStepRegistry].
  final List<OnboardingStep> steps;

  /// The step currently shown.
  OnboardingStep get currentStep => steps[value.currentStepIndex];

  /// Whether [currentStep] is the first step (no step to go back to).
  bool get isFirstStep => value.currentStepIndex == 0;

  /// Whether [currentStep] is the last step (finishing it reaches Home).
  bool get isLastStep => value.currentStepIndex == steps.length - 1;

  @override
  void init() {
    unawaited(_resume());
  }

  /// Persists [answer] for [stepId]'s step immediately — an optimistic
  /// local update first, matching the mockups' inline "Saved" hint.
  void updateAnswer(String stepId, dynamic answer) {
    final next = Map<String, dynamic>.of(value.answers)..[stepId] = answer;
    value = value.copyWith(answers: next);
    unawaited(
      _preferences.update(<String, dynamic>{
        onboardingAnswersPreferenceKey: next,
      }),
    );
  }

  /// Marks [currentStep] completed and advances — the primary
  /// Next/Continue action.
  Future<void> next() => _finishCurrent(OnboardingStepStatus.completed);

  /// Marks [currentStep] skipped and advances — the "Skip for now"/"Not
  /// now" action, only reachable when [OnboardingStep.skip] allows it.
  Future<void> skip() => _finishCurrent(OnboardingStepStatus.skipped);

  /// Steps back to the previous step. A no-op on the first step.
  void back() {
    if (isFirstStep) return;
    _enterStep(value.currentStepIndex - 1);
  }

  /// Makes step [index] current and records its [OnboardingStep.
  /// defaultAnswer] if it has no answer yet.
  void _enterStep(int index) {
    value = value.copyWith(currentStepIndex: index);
    final step = currentStep;
    final defaultAnswer = step.defaultAnswer;
    if (defaultAnswer != null && !value.answers.containsKey(step.id)) {
      updateAnswer(step.id, defaultAnswer);
    }
  }

  /// Reads persisted progress and resumes at the first step with no
  /// recorded status — or, if every step already has one, skips straight
  /// to Home (nothing left to do here).
  Future<void> _resume() async {
    final prefs = await _preferences.getAll();
    final status = decodeOnboardingStepStatus(
      prefs[onboardingStepStatusPreferenceKey],
    );
    final answers = Map<String, dynamic>.of(
      (prefs[onboardingAnswersPreferenceKey] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
    final firstOpen = steps.indexWhere((step) => !status.containsKey(step.id));

    value = value.copyWith(
      stepStatus: status,
      answers: answers,
      resuming: false,
    );
    if (firstOpen == -1) {
      value = value.copyWith(currentStepIndex: steps.length - 1);
      await _finishOnboarding();
    } else {
      _enterStep(firstOpen);
    }
  }

  Future<void> _finishCurrent(OnboardingStepStatus status) async {
    final step = currentStep;
    final nextStatus = Map<String, OnboardingStepStatus>.of(value.stepStatus)
      ..[step.id] = status;
    value = value.copyWith(stepStatus: nextStatus);
    await _preferences.update(<String, dynamic>{
      onboardingStepStatusPreferenceKey: nextStatus.map(
        (key, value) => MapEntry(key, value.name),
      ),
    });
    await step.onFinished?.call(_preferences);
    await _advance();
  }

  Future<void> _advance() async {
    if (isLastStep) {
      await _finishOnboarding();
    } else {
      _enterStep(value.currentStepIndex + 1);
    }
  }

  /// Marks the stepper as walked-through-at-least-once (see
  /// [onboardingCompletedPreferenceKey]) and returns to Home.
  Future<void> _finishOnboarding() async {
    await _preferences.update(<String, dynamic>{
      onboardingCompletedPreferenceKey: true,
    });
    _navigation.go(const HomeRoute().location);
  }
}
