import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/entitlement.dart';
import 'package:billing/src/entitlement_policy.dart';
import 'package:billing/src/entitlement_store.dart';
import 'package:billing/src/subscription_state.dart';

/// Reads an owner's entitlement: the one a Function, a worker or the `billing`
/// action gates on. Server code that must not run for a lapsed owner calls
/// [forOwner] and checks `Entitlement.hasAccess`.
class EntitlementReader {
  /// Creates a reader.
  EntitlementReader({
    required this.store,
    DateTime Function()? clock,
    this.policy = const EntitlementPolicy(),
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  /// Where the states are read from.
  final EntitlementStore store;

  /// The product rules (the grace period).
  final EntitlementPolicy policy;

  final DateTime Function() _clock;

  /// [owner]'s entitlement now: the subscription that grants access, else the
  /// most recent one, else `Entitlement.none`.
  Future<Entitlement> forOwner(BillingOwner owner) async {
    final now = _clock();
    final states = await store.byOwner(owner.key);
    if (states.isEmpty) return Entitlement.none(owner);
    final computed = <(SubscriptionState, Entitlement)>[
      for (final s in states) (s, s.entitlementAt(now, policy)),
    ]..sort((a, b) => b.$1.eventAt.compareTo(a.$1.eventAt));
    for (final (_, entitlement) in computed) {
      if (entitlement.hasAccess) return entitlement;
    }

    return computed.first.$2;
  }
}
