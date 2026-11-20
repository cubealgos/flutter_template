import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/subscription_state.dart';

/// The provider's own view of its subscriptions, read for reconciliation.
abstract interface class ProviderSubscriptions {
  /// The subscription [subscriptionId], or null when the provider has none by
  /// that ID. [knownOwner] is the owner this system has on file for it, used
  /// when the provider's own data does not name one.
  Future<SubscriptionState?> fetch(
    String subscriptionId, {
    BillingOwner? knownOwner,
  });

  /// The provider's subscriptions, as many pages as the adapter reads per
  /// run. A subscription whose owner cannot be told is left out.
  Future<List<SubscriptionState>> list();
}
