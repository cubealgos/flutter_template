import 'package:app/app/billing_owner_resolver.dart';
import 'package:app/app/di.dart';
import 'package:app/features/settings/paywall/layouts/paywall_mobile_layout.dart';
import 'package:app/features/settings/paywall/paywall_controller.dart';
import 'package:app/features/settings/paywall/paywall_model.dart';
import 'package:billing/billing.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// The subscription screen (web billing with a merchant of record): shows the
/// entitlement the server computed, starts a checkout for the chosen
/// quantity, changes the quantity (prorated) and opens the customer portal.
/// Replaces the template's former store-shaped stub; a mobile clone that
/// sells through the App Store or Play Store replaces this screen with its
/// store SDK and the disclosures those stores require (see
/// `apps/app/README.md`, "Billing and the paywall").
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `PaywallMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class PaywallView extends ViewWidget<PaywallModel, PaywallController> {
  /// Creates the view.
  PaywallView({super.key});

  @override
  PaywallController createController() => PaywallController(
    getIt<NavigationService>(),
    getIt<Billing>(),
    getIt<BillingOwnerResolver>(),
    getIt<LauncherService>(),
  );

  @override
  Widget build(
    BuildContext context,
    PaywallController controller,
    PaywallModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => PaywallMobileLayout(
        model: model,
        onBack: controller.goBack,
        onRefresh: controller.refresh,
        onIncrease: controller.increase,
        onDecrease: controller.decrease,
        onSubscribe: controller.subscribe,
        onApplyQuantity: controller.applyQuantity,
        onManage: controller.manage,
        onOpenAgb: controller.openAgb,
        onOpenDatenschutz: controller.openDatenschutz,
      ),
    );
  }
}
