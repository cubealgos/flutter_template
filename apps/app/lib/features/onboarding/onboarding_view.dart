import 'package:app/app/di.dart';
import 'package:app/features/onboarding/layouts/onboarding_desktop_layout.dart';
import 'package:app/features/onboarding/layouts/onboarding_mobile_layout.dart';
import 'package:app/features/onboarding/onboarding_controller.dart';
import 'package:app/features/onboarding/onboarding_model.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Onboarding: a profile-setup stepper (Profile → Preferences →
/// Notifications, by default) over `OnboardingController.steps`, stored
/// per user and resumable — never a carousel/tutorial (see
/// `OnboardingController`'s dartdoc). The step list itself is the per-app
/// extensibility point (`OnboardingStepRegistry`); this view only ever
/// renders whatever steps it's given, generically.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `OnboardingMobileLayout` and
/// `OnboardingDesktopLayout` (no tablet layout — a tablet gets the mobile
/// one), so crossing a breakpoint never recreates the controller or loses
/// the step being answered. Both layouts share `OnboardingScreenFrame`
/// (`AppScreenScaffold`/`AppScreenHeaderBack` and the optional "Skip for
/// now" link).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class OnboardingView extends ViewWidget<OnboardingModel, OnboardingController> {
  /// Creates the view.
  OnboardingView({super.key});

  @override
  OnboardingController createController() => OnboardingController(
    getIt<NavigationService>(),
    getIt<UserPreferences>(),
    steps: getIt<OnboardingStepRegistry>().steps(),
  );

  @override
  Widget build(
    BuildContext context,
    OnboardingController controller,
    OnboardingModel model,
  ) {
    // Resuming is a brief, one-time read at mount (see
    // `OnboardingController._resume`) — nothing meaningful to render yet.
    if (model.resuming) return const SizedBox.shrink();

    final step = controller.currentStep;
    final scope = OnboardingStepScope(
      answer: model.answers[step.id],
      onChanged: (answer) => controller.updateAnswer(step.id, answer),
    );

    return ResponsiveLayout(
      mobile: (_) => OnboardingMobileLayout(
        currentStepIndex: model.currentStepIndex,
        stepCount: controller.steps.length,
        step: step,
        scope: scope,
        onSkip: controller.skip,
        onBack: controller.back,
        onNext: controller.next,
      ),
      desktop: (_) => OnboardingDesktopLayout(
        currentStepIndex: model.currentStepIndex,
        stepCount: controller.steps.length,
        step: step,
        scope: scope,
        onSkip: controller.skip,
        onBack: controller.back,
        onNext: controller.next,
      ),
    );
  }
}
