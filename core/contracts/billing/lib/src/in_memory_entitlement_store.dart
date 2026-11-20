import 'package:billing/src/entitlement_store.dart';
import 'package:billing/src/provider_status.dart';
import 'package:billing/src/subscription_state.dart';

/// An `EntitlementStore` in memory, for tests and `FakeBilling`.
class InMemoryEntitlementStore implements EntitlementStore {
  final Map<String, SubscriptionState> _states = <String, SubscriptionState>{};

  /// How many `put`s happened, to prove a path wrote nothing.
  int writes = 0;

  @override
  Future<SubscriptionState?> bySubscription(String subscriptionId) async =>
      _states[subscriptionId];

  @override
  Future<List<SubscriptionState>> byOwner(String ownerKey) async =>
      _states.values.where((s) => s.owner.key == ownerKey).toList();

  @override
  Future<void> put(SubscriptionState state) async {
    writes++;
    _states[state.subscriptionId] = state;
  }

  @override
  Future<List<SubscriptionState>> dueForReconciliation(int limit) async {
    final open = _states.values
        .where((s) => s.status != ProviderStatus.canceled)
        .toList();
    final sorted = open
      ..sort(
        (a, b) => (a.reconciledAt ?? a.eventAt).compareTo(
          b.reconciledAt ?? b.eventAt,
        ),
      );

    return sorted.take(limit).toList();
  }
}
