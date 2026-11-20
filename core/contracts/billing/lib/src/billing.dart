import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/checkout_session.dart';
import 'package:billing/src/entitlement.dart';
import 'package:billing/src/portal_session.dart';

/// Web billing with a merchant of record, as the app sees it.
///
/// The app never talks to the provider: an implementation calls the `api`
/// Function's `billing` action (`backend/appwrite/adapters`), and the entitlement
/// the app reads is the one the server computed from the ledger. Every method
/// throws a `BillingError` on failure.
abstract interface class Billing {
  /// Starts a checkout of [quantity] units of [plan] for [owner]. Send the
  /// buyer to the session's URL; the subscription appears in [entitlement]
  /// when the provider's webhook has been processed, not before.
  Future<CheckoutSession> startCheckout({
    required String plan,
    required int quantity,
    required BillingOwner owner,
  });

  /// A link into the customer portal for [owner]'s subscription: payment
  /// method, invoices, cancellation.
  Future<PortalSession> openPortal(BillingOwner owner);

  /// Changes [owner]'s subscription to [quantity] units, **prorated**: the
  /// provider charges or credits the difference for the rest of the period.
  /// Returns the entitlement the provider's answer implies; the stored one
  /// follows through the webhook.
  Future<Entitlement> updateQuantity({
    required BillingOwner owner,
    required int quantity,
  });

  /// What [owner] may use now. The server computes it from the subscription's
  /// state and the current time, including the grace period.
  Future<Entitlement> entitlement(BillingOwner owner);
}
