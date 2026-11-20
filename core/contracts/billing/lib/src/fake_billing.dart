import 'package:billing/src/billing.dart';
import 'package:billing/src/billing_error.dart';
import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/checkout_session.dart';
import 'package:billing/src/entitlement.dart';
import 'package:billing/src/entitlement_policy.dart';
import 'package:billing/src/entitlement_reader.dart';
import 'package:billing/src/in_memory_entitlement_store.dart';
import 'package:billing/src/portal_session.dart';
import 'package:billing/src/provider_status.dart';
import 'package:billing/src/subscription_state.dart';

/// A `Billing` that runs in memory: the default when the app runs on the fake
/// backend, and the stand-in for tests.
///
/// A checkout never charges anything. [completeCheckout] plays the provider's
/// webhook that follows a paid one, so a test or a developer can walk the
/// whole flow; [markPastDue] and [cancel] play the others. The entitlement is
/// computed by the same `SubscriptionState.entitlementAt` the server uses.
class FakeBilling implements Billing {
  /// Creates a fake. [plans] limits the plan keys it accepts (null: any).
  FakeBilling({
    this.plans,
    DateTime Function()? clock,
    this.policy = const EntitlementPolicy(),
  }) : _clock = clock ?? (() => DateTime.now().toUtc()) {
    _reader = EntitlementReader(store: _store, policy: policy, clock: _clock);
  }

  /// The plan keys accepted, or null for any.
  final Set<String>? plans;

  /// The grace period and other product rules.
  final EntitlementPolicy policy;

  /// Quantity changes asked for, in order (`prorated` is always true).
  final List<({BillingOwner owner, int quantity, bool prorated})>
  quantityChanges = <({BillingOwner owner, int quantity, bool prorated})>[];

  final DateTime Function() _clock;
  final InMemoryEntitlementStore _store = InMemoryEntitlementStore();
  // Assigned in the constructor body, after the clock exists.
  // ignore: solid_lints/avoid_late_keyword
  late final EntitlementReader _reader;
  final Map<String, ({String plan, int quantity, BillingOwner owner})>
  _pending = <String, ({String plan, int quantity, BillingOwner owner})>{};
  int _counter = 0;

  @override
  Future<CheckoutSession> startCheckout({
    required String plan,
    required int quantity,
    required BillingOwner owner,
  }) async {
    if (plan.isEmpty || quantity < 1) {
      throw const BillingInvalidError('A plan and a quantity of at least 1.');
    }
    final allowed = plans;
    if (allowed != null && !allowed.contains(plan)) {
      throw BillingUnknownPlanError(plan);
    }
    final id = 'txn_fake_${++_counter}';
    _pending[id] = (plan: plan, quantity: quantity, owner: owner);

    return CheckoutSession(
      url: Uri.parse('https://checkout.fake.invalid/pay?_ptxn=$id'),
      transactionId: id,
    );
  }

  /// Plays the webhook after the buyer paid transaction [transactionId]: the
  /// subscription becomes active.
  Future<void> completeCheckout(String transactionId) async {
    final pending = _pending.remove(transactionId);
    if (pending == null) throw StateError('No pending checkout $transactionId');
    final now = _clock();
    await _store.put(
      SubscriptionState(
        subscriptionId: 'sub_fake_${pending.owner.id}',
        customerId: 'ctm_fake_${pending.owner.id}',
        owner: pending.owner,
        plan: pending.plan,
        quantity: pending.quantity,
        status: ProviderStatus.active,
        nextBilledAt: now.add(const Duration(days: 30)),
        currentPeriodEnd: now.add(const Duration(days: 30)),
        eventAt: now,
      ),
    );
  }

  /// Plays a failed payment for [owner]: past due from now on.
  Future<void> markPastDue(BillingOwner owner) => _change(
    owner,
    (s) => SubscriptionState(
      subscriptionId: s.subscriptionId,
      customerId: s.customerId,
      owner: s.owner,
      plan: s.plan,
      quantity: s.quantity,
      status: ProviderStatus.pastDue,
      nextBilledAt: s.nextBilledAt,
      currentPeriodEnd: s.currentPeriodEnd,
      pastDueSince: _clock(),
      eventAt: _clock(),
    ),
  );

  /// Plays the end of [owner]'s subscription.
  Future<void> cancel(BillingOwner owner) => _change(
    owner,
    (s) => SubscriptionState(
      subscriptionId: s.subscriptionId,
      customerId: s.customerId,
      owner: s.owner,
      plan: s.plan,
      quantity: s.quantity,
      status: ProviderStatus.canceled,
      canceledAt: _clock(),
      eventAt: _clock(),
    ),
  );

  Future<void> _change(
    BillingOwner owner,
    SubscriptionState Function(SubscriptionState) change,
  ) async {
    final states = await _store.byOwner(owner.key);
    if (states.isEmpty) throw const BillingNoSubscriptionError();
    await _store.put(change(states.last));
  }

  @override
  Future<PortalSession> openPortal(BillingOwner owner) async {
    final states = await _store.byOwner(owner.key);
    if (states.isEmpty) throw const BillingNoSubscriptionError();

    return PortalSession(
      url: Uri.parse('https://portal.fake.invalid/${states.last.customerId}'),
    );
  }

  @override
  Future<Entitlement> updateQuantity({
    required BillingOwner owner,
    required int quantity,
  }) async {
    if (quantity < 1) {
      throw const BillingInvalidError('A quantity of at least 1.');
    }
    final states = await _store.byOwner(owner.key);
    if (states.isEmpty) throw const BillingNoSubscriptionError();
    final s = states.last;
    quantityChanges.add((owner: owner, quantity: quantity, prorated: true));
    await _store.put(
      SubscriptionState(
        subscriptionId: s.subscriptionId,
        customerId: s.customerId,
        owner: s.owner,
        plan: s.plan,
        quantity: quantity,
        status: s.status,
        nextBilledAt: s.nextBilledAt,
        currentPeriodEnd: s.currentPeriodEnd,
        pastDueSince: s.pastDueSince,
        eventAt: _clock(),
      ),
    );

    return await _reader.forOwner(owner);
  }

  @override
  Future<Entitlement> entitlement(BillingOwner owner) =>
      _reader.forOwner(owner);
}
