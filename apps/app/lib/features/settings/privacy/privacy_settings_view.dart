import 'package:app/app/di.dart';
import 'package:app/features/settings/privacy/layouts/privacy_settings_mobile_layout.dart';
import 'package:app/features/settings/privacy/privacy_settings_controller.dart';
import 'package:app/features/settings/privacy/privacy_settings_model.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Settings → Privacy: change consent (withdrawable at any time) and
/// export the user's own data with step-up re-verification.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `PrivacySettingsMobileLayout` (mobile only — every
/// wider viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class PrivacySettingsView
    extends ViewWidget<PrivacySettingsModel, PrivacySettingsController> {
  /// Creates the view.
  PrivacySettingsView({super.key});

  @override
  PrivacySettingsController createController() => PrivacySettingsController(
    getIt<NavigationService>(),
    getIt<UserPreferences>(),
    getIt<AuthService>(),
    getIt<DocumentRepository>(),
    getIt<ClipboardService>(),
  );

  @override
  Widget build(
    BuildContext context,
    PrivacySettingsController controller,
    PrivacySettingsModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => PrivacySettingsMobileLayout(
        model: model,
        stepUpCodeController: controller.stepUpCodeController,
        onBack: controller.goBack,
        onSetConsent: (accepted) => controller.setConsent(accepted: accepted),
        onStartExport: controller.startExport,
        onVerifyStepUpAndExport: controller.verifyStepUpAndExport,
        onCopyExportedJson: controller.copyExportedJson,
      ),
    );
  }
}
