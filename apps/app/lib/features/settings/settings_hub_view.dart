import 'package:app/app/config.dart';
import 'package:app/app/di.dart';
import 'package:app/features/settings/layouts/settings_hub_mobile_layout.dart';
import 'package:app/features/settings/settings_hub_controller.dart';
import 'package:app/features/settings/settings_hub_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// The Settings hub: Legal, Privacy, Account and (behind
/// `AppConfig.paywall`) Subscription.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `SettingsHubMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class SettingsHubView
    extends ViewWidget<SettingsHubModel, SettingsHubController> {
  /// Creates the view.
  SettingsHubView({super.key});

  @override
  SettingsHubController createController() =>
      SettingsHubController(getIt<NavigationService>(), getIt<AppConfig>());

  @override
  Widget build(
    BuildContext context,
    SettingsHubController controller,
    SettingsHubModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => SettingsHubMobileLayout(
        model: model,
        onBack: controller.goBack,
        onOpenLegal: controller.openLegal,
        onOpenPrivacy: controller.openPrivacy,
        onOpenAccount: controller.openAccount,
        onOpenTeams: controller.openTeams,
        onOpenPaywall: controller.openPaywall,
      ),
    );
  }
}
