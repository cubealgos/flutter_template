import 'package:billing/src/ledger_kind.dart';
import 'package:billing/src/scheduled_change.dart';
import 'package:billing/src/subscription_state.dart';

/// One effect a provider event has, in provider-neutral form. An adapter's
/// parser turns an event into one or more of these; `BillingEngine` writes a
/// ledger row for each, then applies it.
class LedgerChange {
  /// The subscription's state as of the event.
  const LedgerChange.subscription(SubscriptionState this.state)
    : kind = LedgerKind.subscription,
      subscriptionId = null,
      scheduled = null,
      detail = null;

  /// The scheduled change of [subscriptionId] as of the event: [change], or
  /// none when it is null.
  const LedgerChange.scheduledChange({
    required String this.subscriptionId,
    ScheduledChange? change,
  }) : kind = LedgerKind.scheduledChange,
       state = null,
       scheduled = change,
       detail = null;

  /// An event with no effect: only [detail] says why it was kept.
  const LedgerChange.recorded({this.subscriptionId, this.detail})
    : kind = LedgerKind.recorded,
      state = null,
      scheduled = null;

  /// What the change is.
  final LedgerKind kind;

  /// For [LedgerKind.subscription]: the state.
  final SubscriptionState? state;

  /// For [LedgerKind.scheduledChange]: the pending change, or null for none.
  final ScheduledChange? scheduled;

  /// The subscription a scheduled change or a recorded event concerns (the
  /// subscription kind carries it in [state]).
  final String? subscriptionId;

  /// For [LedgerKind.recorded]: why.
  final String? detail;
}
