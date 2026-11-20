import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/entitlement.dart';
import 'package:billing/src/entitlement_policy.dart';
import 'package:billing/src/entitlement_status.dart';
import 'package:billing/src/provider_status.dart';
import 'package:billing/src/scheduled_action.dart';
import 'package:billing/src/scheduled_change.dart';
import 'package:billing/src/state_source.dart';

/// One subscription as the entitlement store keeps it: the provider's view
/// at [eventAt], folded from the ledger by `BillingEngine` or corrected by
/// `BillingReconciler`. [entitlementAt] turns it into what the owner may do
/// at a given time.
class SubscriptionState {
  /// Creates a state.
  const SubscriptionState({
    required this.subscriptionId,
    required this.owner,
    required this.plan,
    required this.quantity,
    required this.status,
    required this.eventAt,
    this.customerId,
    this.currentPeriodEnd,
    this.nextBilledAt,
    this.canceledAt,
    this.pastDueSince,
    this.scheduledChange,
    this.reconciledAt,
    this.source = StateSource.webhook,
  });

  /// The provider's subscription ID.
  final String subscriptionId;

  /// The provider's customer ID, which the portal needs.
  final String? customerId;

  /// Who the subscription is billed to.
  final BillingOwner owner;

  /// The plan key.
  final String plan;

  /// Units paid for.
  final int quantity;

  /// The provider's status.
  final ProviderStatus status;

  /// The end of the current billing period.
  final DateTime? currentPeriodEnd;

  /// The next renewal.
  final DateTime? nextBilledAt;

  /// When it was canceled.
  final DateTime? canceledAt;

  /// When the status last became past due (the start of the grace period);
  /// null in any other status. State, not an event: the end of the grace
  /// period is [entitlementAt]'s arithmetic.
  final DateTime? pastDueSince;

  /// A change the provider has scheduled.
  final ScheduledChange? scheduledChange;

  /// The time of the newest provider event this state reflects: an older
  /// event arriving later is not applied over it.
  final DateTime eventAt;

  /// What wrote it.
  final StateSource source;

  /// When `BillingReconciler` last compared it with the provider.
  final DateTime? reconciledAt;

  /// A copy whose scheduled change is [scheduledChange] (null clears it) and
  /// whose [eventAt] is moved.
  SubscriptionState withScheduledChange(
    ScheduledChange? scheduledChange, {
    required DateTime eventAt,
  }) => _with(
    scheduledChange: scheduledChange,
    clearScheduled: true,
  )._withEventAt(eventAt);

  /// A copy compared with the provider just now.
  SubscriptionState reconciledAtTime(DateTime now) => SubscriptionState(
    subscriptionId: subscriptionId,
    customerId: customerId,
    owner: owner,
    plan: plan,
    quantity: quantity,
    status: status,
    currentPeriodEnd: currentPeriodEnd,
    nextBilledAt: nextBilledAt,
    canceledAt: canceledAt,
    pastDueSince: pastDueSince,
    scheduledChange: scheduledChange,
    eventAt: eventAt,
    source: source,
    reconciledAt: now,
  );

  /// This snapshot, from the event that happened at [at], applied over what is
  /// stored ([previous], if anything): the snapshot's fields, the stored
  /// scheduled change (a separate change of the same event replaces it), and a
  /// past-due start that survives until the status leaves past due.
  SubscriptionState foldedOver(SubscriptionState? previous, DateTime at) =>
      _merged(
        previous,
        _Provenance(
          eventAt: at,
          scheduled: scheduledChange ?? previous?.scheduledChange,
          since: at,
          source: StateSource.webhook,
          reconciledAt: previous?.reconciledAt,
        ),
      );

  /// This state, read from the provider **now**, as the correction of
  /// [previous]: every field is the provider's, `eventAt` never moves
  /// backwards, and a past-due start is kept.
  SubscriptionState correctionOf(SubscriptionState? previous, DateTime now) =>
      _merged(
        previous,
        _Provenance(
          eventAt: previous != null && previous.eventAt.isAfter(eventAt)
              ? previous.eventAt
              : eventAt,
          scheduled: scheduledChange,
          since: now,
          source: StateSource.reconciler,
          reconciledAt: now,
          keepOwner: true,
        ),
      );

  SubscriptionState _merged(SubscriptionState? previous, _Provenance how) {
    return SubscriptionState(
      subscriptionId: subscriptionId,
      customerId: customerId ?? previous?.customerId,
      owner: how.keepOwner ? previous?.owner ?? owner : owner,
      plan: plan,
      quantity: quantity,
      status: status,
      currentPeriodEnd: currentPeriodEnd,
      nextBilledAt: nextBilledAt,
      canceledAt: canceledAt,
      pastDueSince: _pastDueStart(previous, how.since),
      scheduledChange: how.scheduled,
      eventAt: how.eventAt,
      source: how.source,
      reconciledAt: how.reconciledAt,
    );
  }

  /// The start of the grace period: kept while the status stays past due.
  DateTime? _pastDueStart(SubscriptionState? previous, DateTime fallback) {
    if (status != ProviderStatus.pastDue) return null;
    final kept = previous?.status == ProviderStatus.pastDue
        ? previous?.pastDueSince
        : null;

    return kept ?? fallback;
  }

  SubscriptionState _with({
    ScheduledChange? scheduledChange,
    bool clearScheduled = false,
  }) => SubscriptionState(
    subscriptionId: subscriptionId,
    customerId: customerId,
    owner: owner,
    plan: plan,
    quantity: quantity,
    status: status,
    currentPeriodEnd: currentPeriodEnd,
    nextBilledAt: nextBilledAt,
    canceledAt: canceledAt,
    pastDueSince: pastDueSince,
    scheduledChange: clearScheduled ? scheduledChange : this.scheduledChange,
    eventAt: eventAt,
    source: source,
    reconciledAt: reconciledAt,
  );

  SubscriptionState _withEventAt(DateTime at) => SubscriptionState(
    subscriptionId: subscriptionId,
    customerId: customerId,
    owner: owner,
    plan: plan,
    quantity: quantity,
    status: status,
    currentPeriodEnd: currentPeriodEnd,
    nextBilledAt: nextBilledAt,
    canceledAt: canceledAt,
    pastDueSince: pastDueSince,
    scheduledChange: scheduledChange,
    eventAt: at,
    source: source,
    reconciledAt: reconciledAt,
  );

  /// What the owner may do at [now] under [policy].
  Entitlement entitlementAt(
    DateTime now, [
    EntitlementPolicy policy = const EntitlementPolicy(),
  ]) {
    switch (status) {
      case ProviderStatus.canceled:
        return _entitled(EntitlementStatus.canceled, access: false);
      case ProviderStatus.paused:
        return _entitled(EntitlementStatus.paused, access: false);
      case ProviderStatus.pastDue:
        final graceEnds = (pastDueSince ?? eventAt).add(policy.grace);

        return now.isBefore(graceEnds)
            ? _entitled(
                EntitlementStatus.pastDue,
                access: true,
                graceEnds: graceEnds,
              )
            : _entitled(
                EntitlementStatus.expired,
                access: false,
                graceEnds: graceEnds,
              );
      case ProviderStatus.active:
      case ProviderStatus.trialing:
        return _whileSubscribed(now);
    }
  }

  DateTime? _scheduledAt(ScheduledAction action) =>
      scheduledChange?.action == action ? scheduledChange?.effectiveAt : null;

  Entitlement _whileSubscribed(DateTime now) {
    final cancelsAt = _scheduledAt(ScheduledAction.cancel);
    final pausesAt = _scheduledAt(ScheduledAction.pause);
    bool reached(DateTime? at) => at != null && !now.isBefore(at);
    if (reached(cancelsAt)) {
      return _entitled(EntitlementStatus.canceled, access: false);
    }
    if (reached(pausesAt)) {
      return _entitled(EntitlementStatus.paused, access: false);
    }

    return _entitled(
      status == ProviderStatus.trialing
          ? EntitlementStatus.trialing
          : EntitlementStatus.active,
      access: true,
      renews: cancelsAt == null ? nextBilledAt : null,
    );
  }

  Entitlement _entitled(
    EntitlementStatus status, {
    required bool access,
    DateTime? renews,
    DateTime? graceEnds,
  }) => Entitlement(
    owner: owner,
    plan: plan,
    quantity: quantity,
    status: status,
    hasAccess: access,
    renewsAt: renews,
    cancelsAt: _scheduledAt(ScheduledAction.cancel),
    graceEndsAt: graceEnds,
  );
}

/// How a state is merged over its predecessor: what differs between a webhook
/// fold and a reconciler correction.
class _Provenance {
  const _Provenance({
    required this.eventAt,
    required this.scheduled,
    required this.since,
    required this.source,
    required this.reconciledAt,
    this.keepOwner = false,
  });

  final DateTime eventAt;
  final ScheduledChange? scheduled;
  final DateTime since;
  final StateSource source;
  final DateTime? reconciledAt;
  final bool keepOwner;
}
