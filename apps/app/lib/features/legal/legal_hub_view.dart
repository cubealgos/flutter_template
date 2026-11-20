import 'package:app/app/config.dart';
import 'package:app/app/di.dart';
import 'package:app/features/legal/layouts/legal_hub_mobile_layout.dart';
import 'package:app/features/legal/legal_hub_controller.dart';
import 'package:app/features/legal/legal_hub_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// The Legal hub: a tappable list to each legal document, reachable
/// pre-login (from the sign-in screen) and post-login (from Settings).
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `LegalHubMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class LegalHubView extends ViewWidget<LegalHubModel, LegalHubController> {
  /// Creates the view.
  LegalHubView({super.key});

  @override
  LegalHubController createController() =>
      LegalHubController(getIt<NavigationService>(), getIt<AppConfig>());

  @override
  Widget build(
    BuildContext context,
    LegalHubController controller,
    LegalHubModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => LegalHubMobileLayout(
        model: model,
        onBack: controller.goBack,
        onOpenImpressum: controller.openImpressum,
        onOpenDatenschutz: controller.openDatenschutz,
        onOpenAgb: controller.openAgb,
        onOpenBarrierefreiheit: controller.openBarrierefreiheit,
        onOpenLicences: controller.openLicences,
      ),
    );
  }
}
