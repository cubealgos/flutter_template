import 'package:billing/billing.dart';
import 'package:paddle_billing/src/billing_access.dart';
import 'package:paddle_billing/src/paddle_api.dart';
import 'package:paddle_billing/src/paddle_api_exception.dart';
import 'package:paddle_billing/src/paddle_plans.dart';
import 'package:paddle_billing/src/paddle_subscription_mapper.dart';

/// The server-side implementation of the `Billing` operations, for a
/// signed-in caller: it checks the caller may act for the owner, then calls
/// Paddle. It **never writes an entitlement or the ledger**: the entitlement
/// follows the provider's webhook, so there is one path into it. Every failure
/// is a `BillingError`; the Paddle detail goes to the log only.
class BillingService {
  /// Creates the service. [api] is null when billing is not configured.
  BillingService({
    required this.access,
    required this.entitlements,
    required this.plans,
    required this.policy,
    this.api,
    this.log,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  /// Who may do what.
  final BillingAccess access;

  /// Where the states are read from.
  final EntitlementStore entitlements;

  /// The plans.
  final PaddlePlans plans;

  /// The grace period.
  final EntitlementPolicy policy;

  /// The Paddle client, or null when no API key is configured.
  final PaddleApi? api;

  /// A sink for the Paddle details a user must not see.
  final void Function(String message)? log;

  final DateTime Function() _clock;

  EntitlementReader get _reader =>
      EntitlementReader(store: entitlements, policy: policy, clock: _clock);

  PaddleApi get _api => api ?? (throw const BillingNotConfiguredError());

  /// Starts a checkout. Refuses when [owner] already has a subscription that
  /// grants access (change its quantity or use the portal instead).
  Future<CheckoutSession> startCheckout({
    required String caller,
    required String plan,
    required int quantity,
    required BillingOwner owner,
  }) async {
    if (plan.isEmpty || quantity < 1) {
      throw const BillingInvalidError('A plan and a quantity of at least 1.');
    }
    final priceId = plans.priceFor(plan);
    if (priceId == null) throw BillingUnknownPlanError(plan);
    await _requireManage(caller, owner);
    final current = await _reader.forOwner(owner);
    if (current.hasAccess) {
      throw const BillingInvalidError(
        'This account already has a subscription: change it in the portal.',
      );
    }
    final customerId = (await _subscriptionOf(owner))?.customerId;

    return await _provider(
      () => _api.createTransaction(
        priceId: priceId,
        quantity: quantity,
        owner: owner,
        customerId: customerId,
      ),
    );
  }

  /// A link into the customer portal for [owner]'s subscription.
  Future<PortalSession> openPortal({
    required String caller,
    required BillingOwner owner,
  }) async {
    await _requireManage(caller, owner);
    final state = await _subscriptionOf(owner);
    final customerId = state?.customerId;
    if (state == null || customerId == null) {
      throw const BillingNoSubscriptionError();
    }
    final url = await _provider(
      () => _api.createPortalSession(
        customerId: customerId,
        subscriptionIds: <String>[state.subscriptionId],
      ),
    );

    return PortalSession(url: url);
  }

  /// Changes [owner]'s subscription to [quantity] units, prorated. Returns the
  /// entitlement Paddle's answer implies (not stored: the webhook that follows
  /// stores it).
  Future<Entitlement> updateQuantity({
    required String caller,
    required BillingOwner owner,
    required int quantity,
  }) async {
    if (quantity < 1) {
      throw const BillingInvalidError('A quantity of at least 1.');
    }
    await _requireManage(caller, owner);
    final state = await _subscriptionOf(owner);
    if (state == null || !state.entitlementAt(_clock(), policy).hasAccess) {
      throw const BillingNoSubscriptionError();
    }
    final priceId = plans.priceFor(state.plan) ?? state.plan;
    final entity = await _provider(
      () => _api.updateQuantity(
        subscriptionId: state.subscriptionId,
        priceId: priceId,
        quantity: quantity,
      ),
    );
    final updated = PaddleSubscriptionMapper(plans).stateOf(
      entity,
      eventAt: _clock(),
      fallbackOwner: owner,
      withScheduledChange: true,
    );

    return updated?.entitlementAt(_clock(), policy) ??
        state.entitlementAt(_clock(), policy);
  }

  /// [owner]'s entitlement now, for a trusted server-side caller (a worker
  /// gating a job): no membership check.
  Future<Entitlement> entitlementOf(BillingOwner owner) =>
      _reader.forOwner(owner);

  /// [owner]'s entitlement now, for [caller], who must be allowed to read it.
  Future<Entitlement> entitlement({
    required String caller,
    required BillingOwner owner,
  }) async {
    if (!await access.mayRead(caller, owner)) {
      throw const BillingForbiddenError('Not a member of this account.');
    }

    return await _reader.forOwner(owner);
  }

  Future<void> _requireManage(String caller, BillingOwner owner) async {
    if (!await access.mayManage(caller, owner)) {
      throw const BillingForbiddenError(
        'Only the account owner or a team admin can manage billing.',
      );
    }
  }

  /// The subscription to act on: one that grants access, else the newest.
  Future<SubscriptionState?> _subscriptionOf(BillingOwner owner) async {
    final states = await entitlements.byOwner(owner.key);
    if (states.isEmpty) return null;
    final now = _clock();
    final sorted = states.toList()
      ..sort((a, b) => b.eventAt.compareTo(a.eventAt));

    return sorted.firstWhere(
      (s) => s.entitlementAt(now, policy).hasAccess,
      orElse: () => sorted.first,
    );
  }

  Future<T> _provider<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PaddleApiException catch (e) {
      log?.call('paddle call failed: $e');

      throw const BillingProviderError(
        'The payment provider could not complete that. Try again later.',
      );
    }
  }
}
