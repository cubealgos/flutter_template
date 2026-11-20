import 'package:app/app/di.dart';
import 'package:app/features/home/home_controller.dart';
import 'package:app/features/home/home_model.dart';
import 'package:app/features/home/layouts/home_desktop_layout.dart';
import 'package:app/features/home/layouts/home_mobile_layout.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// The signed-in landing screen: the plan's "empty state" (a cloned app
/// fills this in with its real content) plus the "Finish your setup"
/// card, shown while any onboarding step is still open and linking back
/// into the stepper — see `HomeController.showSetupCard`.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `HomeMobileLayout` and `HomeDesktopLayout` (no
/// tablet layout — a tablet gets the mobile one), so crossing a breakpoint
/// never recreates the controller. Both layouts use `AppScreenScaffold`'s
/// full-bleed header layout (spec.md §2.6).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class HomeView extends ViewWidget<HomeModel, HomeController> {
  /// Creates the view.
  HomeView({super.key});

  @override
  HomeController createController() => HomeController(
    getIt<NavigationService>(),
    getIt<AuthService>(),
    getIt<DialogService>(),
    getIt<UserPreferences>(),
    onboardingSteps: getIt<OnboardingStepRegistry>().steps(),
  );

  @override
  Widget build(
    BuildContext context,
    HomeController controller,
    HomeModel model,
  ) {
    final showSetupCard = controller.showSetupCard;

    return ResponsiveLayout(
      mobile: (_) => HomeMobileLayout(
        showSetupCard: showSetupCard,
        completedStepCount: model.completedStepCount,
        totalStepCount: model.totalStepCount,
        openSteps: model.openSteps,
        onDismissSetupCard: controller.dismissSetupCard,
        onOpenOnboarding: controller.openOnboarding,
        onSignOut: controller.signOut,
        onOpenSettings: controller.openSettings,
      ),
      desktop: (_) => HomeDesktopLayout(
        showSetupCard: showSetupCard,
        completedStepCount: model.completedStepCount,
        totalStepCount: model.totalStepCount,
        openSteps: model.openSteps,
        onDismissSetupCard: controller.dismissSetupCard,
        onOpenOnboarding: controller.openOnboarding,
        onSignOut: controller.signOut,
        onOpenSettings: controller.openSettings,
      ),
    );
  }
}
