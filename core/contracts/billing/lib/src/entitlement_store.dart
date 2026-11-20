import 'package:billing/src/subscription_state.dart';

/// Where subscription states are kept, one per provider subscription.
abstract interface class EntitlementStore {
  /// The state of [subscriptionId], or null.
  Future<SubscriptionState?> bySubscription(String subscriptionId);

  /// Every state of [ownerKey] (an owner may have an old, ended
  /// subscription and a current one).
  Future<List<SubscriptionState>> byOwner(String ownerKey);

  /// Creates or replaces the state of `state.subscriptionId`.
  Future<void> put(SubscriptionState state);

  /// Up to [limit] states that are not canceled, the ones compared with the
  /// provider longest ago first.
  Future<List<SubscriptionState>> dueForReconciliation(int limit);
}
