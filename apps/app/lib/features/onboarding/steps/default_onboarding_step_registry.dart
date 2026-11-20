import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/onboarding/steps/notifications_step.dart';
import 'package:app/features/onboarding/steps/preferences_step.dart';
import 'package:app/features/onboarding/steps/profile_step.dart';

/// The template's own default [OnboardingStepRegistry]: Profile →
/// Preferences → Notifications.
///
/// A clone that wants a different set of onboarding steps registers its
/// own [OnboardingStepRegistry] implementation in
/// `ServiceModule.onboardingStepRegistry` instead of this one — adding,
/// removing or reordering steps needs no change to
/// `OnboardingController`/`OnboardingView`, only to whichever registry is
/// wired up there.
class DefaultOnboardingStepRegistry implements OnboardingStepRegistry {
  /// Creates the default registry.
  const DefaultOnboardingStepRegistry();

  @override
  List<OnboardingStep> steps() => <OnboardingStep>[
    profileOnboardingStep(),
    preferencesOnboardingStep(),
    notificationsOnboardingStep(),
  ];
}
