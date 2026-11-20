import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'onboarding_model.freezed.dart';

/// `OnboardingView`'s view model: a profile-setup stepper (Profile →
/// Preferences → Notifications, by default — see `OnboardingStepRegistry`
/// for how a clone changes the step list), never a carousel/tutorial (see
/// the plan's "Default screens" section, which cites NN/g's evidence
/// against onboarding carousels).
@freezed
abstract class OnboardingModel with _$OnboardingModel implements ViewModel {
  /// Creates the model.
  const factory OnboardingModel({
    /// The index, into `OnboardingController.steps`, of the step currently
    /// shown.
    @Default(0) int currentStepIndex,

    /// Whether the initial resume-from-persistence read is still in
    /// flight — `true` only for the brief window between construction and
    /// `OnboardingController.init` finishing.
    @Default(true) bool resuming,

    /// Every step's persisted status so far, keyed by `OnboardingStep.id`.
    /// A step with no entry has neither been completed nor skipped.
    @Default(<String, OnboardingStepStatus>{})
    Map<String, OnboardingStepStatus> stepStatus,

    /// Every step's persisted answer so far, keyed by `OnboardingStep.id`.
    @Default(<String, dynamic>{}) Map<String, dynamic> answers,
  }) = _OnboardingModel;
}
