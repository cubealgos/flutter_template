import 'dart:async';

import 'package:app/app/billing_owner_resolver.dart';
import 'package:app/app/billing_plans.dart';
import 'package:app/app/router.dart';
import 'package:app/features/settings/paywall/paywall_model.dart';
import 'package:billing/billing.dart';
import 'package:mvc/mvc.dart';

/// Drives `PaywallView`: reads the owner's entitlement, starts a checkout,
/// opens the customer portal and changes the quantity (prorated).
///
/// Everything provider-shaped happens on the server (`Billing` is the `api`
/// Function's `billing` action): the checkout and portal are URLs opened in
/// the browser, and the entitlement shown is the one the server computed from
/// the webhook ledger, so after paying the user refreshes (the webhook may
/// land a moment later). A [BillingError] becomes [PaywallModel.failed], never
/// an exception into the view. Navigation and URL launching go through the
/// injected services, per the MVC controller rule.
class PaywallController extends ViewController<PaywallModel> {
  /// Creates the controller.
  PaywallController(
    this._navigation,
    this._billing,
    this._owners,
    this._launcher,
  ) : super(const PaywallModel());

  final NavigationService _navigation;
  final Billing _billing;
  final BillingOwnerResolver _owners;
  final LauncherService _launcher;

  @override
  void init() {
    unawaited(refresh());
  }

  /// Loads the entitlement again (also after returning from a checkout).
  Future<void> refresh() async {
    final owner = await _owners.resolve();
    if (owner == null) {
      value = value.copyWith(loading: false, signedOut: true);

      return;
    }
    await _attempt(() async {
      final entitlement = await _billing.entitlement(owner);
      value = value.copyWith(
        entitlement: entitlement,
        quantity: entitlement.quantity > 0
            ? entitlement.quantity
            : value.quantity,
        loading: false,
        signedOut: false,
      );
    });
  }

  /// Raises the chosen quantity by one.
  void increase() => value = value.copyWith(quantity: value.quantity + 1);

  /// Lowers the chosen quantity by one, to at least one.
  void decrease() {
    if (value.quantity > 1) {
      value = value.copyWith(quantity: value.quantity - 1);
    }
  }

  /// Starts a checkout for the chosen quantity and opens it in the browser.
  Future<void> subscribe() => _withOwner((owner) async {
    final session = await _billing.startCheckout(
      plan: defaultBillingPlan,
      quantity: value.quantity,
      owner: owner,
    );
    await _launcher.openUrl(session.url, external: true);
  });

  /// Opens the customer portal (payment method, invoices, cancellation).
  Future<void> manage() => _withOwner((owner) async {
    final session = await _billing.openPortal(owner);
    await _launcher.openUrl(session.url, external: true);
  });

  /// Changes the subscription to the chosen quantity, prorated.
  Future<void> applyQuantity() => _withOwner((owner) async {
    final entitlement = await _billing.updateQuantity(
      owner: owner,
      quantity: value.quantity,
    );
    value = value.copyWith(entitlement: entitlement);
  });

  /// Opens the AGB (terms & conditions) legal document.
  void openAgb() => _navigation.push(const AgbRoute().location);

  /// Opens the Datenschutz (privacy policy) legal document.
  void openDatenschutz() => _navigation.push(const DatenschutzRoute().location);

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }

  Future<void> _withOwner(
    Future<void> Function(BillingOwner owner) call,
  ) async {
    if (value.busy) return;
    final owner = await _owners.resolve();
    if (owner == null) {
      value = value.copyWith(signedOut: true);

      return;
    }
    value = value.copyWith(busy: true, failed: false);
    await _attempt(() => call(owner));
    value = value.copyWith(busy: false);
  }

  Future<void> _attempt(Future<void> Function() call) async {
    try {
      await call();
    } on BillingError {
      value = value.copyWith(failed: true, loading: false);
    }
  }
}
