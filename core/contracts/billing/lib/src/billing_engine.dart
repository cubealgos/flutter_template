// The engine reads the members of the states it applies.
// ignore_for_file: solid_lints/feature_envy

import 'package:billing/src/billing_ledger.dart';
import 'package:billing/src/entitlement_store.dart';
import 'package:billing/src/ledger_change.dart';
import 'package:billing/src/ledger_entry.dart';
import 'package:billing/src/ledger_kind.dart';
import 'package:billing/src/provider_event.dart';
import 'package:billing/src/scheduled_change.dart';
import 'package:billing/src/subscription_state.dart';
import 'package:billing/src/webhook_outcome.dart';
import 'package:billing/src/webhook_status.dart';

/// Turns a verified provider event into ledger rows and entitlement changes.
///
/// **The order is the guarantee.** For each change the row is appended first;
/// only a row that was new has its effect applied. A replayed event finds its
/// rows already there and does nothing, and an event whose append fails never
/// touches an entitlement. An event of several changes writes `<id>#1`,
/// `<id>#2`, ...; a crash between two of them is finished by the provider's
/// redelivery, which skips the rows that exist and applies the rest.
///
/// The entitlement update is a read then a write (the stores have no
/// compare-and-set), ordered by the event's own time: an event older than the
/// state is recorded and not applied. Two *concurrent* events for one
/// subscription can still overwrite each other; the reconciler repairs that
/// from the provider's data.
class BillingEngine {
  /// Creates an engine over [ledger] and [entitlements].
  BillingEngine({
    required this.ledger,
    required this.entitlements,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  /// Where rows are appended.
  final BillingLedger ledger;

  /// Where the entitlement states are kept.
  final EntitlementStore entitlements;

  final DateTime Function() _clock;

  /// Records and applies [event].
  Future<WebhookOutcome> process(ProviderEvent event) async {
    final changes = event.changes;
    var recorded = 0;
    var applied = 0;
    var skipped = 0;
    for (var i = 0; i < changes.length; i++) {
      final key = changes.length == 1 ? event.id : '${event.id}#${i + 1}';
      final inserted = await ledger.append(_entryFor(key, event, changes[i]));
      if (!inserted) continue;
      recorded++;
      // The side effect, only after the row is written.
      if (await _apply(changes[i], event)) {
        applied++;
      } else {
        skipped++;
      }
    }

    return WebhookOutcome(
      status: recorded == 0 ? WebhookStatus.replayed : WebhookStatus.accepted,
      recorded: recorded,
      applied: applied,
      skipped: skipped,
    );
  }

  LedgerEntry _entryFor(String key, ProviderEvent event, LedgerChange change) {
    final state = change.state;

    return LedgerEntry(
      key: key,
      eventId: event.id,
      eventType: event.type,
      kind: change.kind,
      occurredAt: event.occurredAt,
      receivedAt: _clock(),
      bodyHash: event.bodyHash,
      subscriptionId: state?.subscriptionId ?? change.subscriptionId,
      ownerKey: state?.owner.key,
      status: state?.status.wire,
      quantity: state?.quantity,
      plan: state?.plan,
      detail: change.detail,
    );
  }

  Future<bool> _apply(LedgerChange change, ProviderEvent event) async {
    final state = change.state;
    final subscriptionId = change.subscriptionId;
    if (change.kind == LedgerKind.subscription && state != null) {
      return await _applySubscription(state, event.occurredAt);
    }
    if (change.kind == LedgerKind.scheduledChange && subscriptionId != null) {
      return await _applyScheduled(subscriptionId, change.scheduled, event);
    }

    return false;
  }

  Future<bool> _applyScheduled(
    String subscriptionId,
    ScheduledChange? scheduled,
    ProviderEvent event,
  ) async {
    final previous = await entitlements.bySubscription(subscriptionId);
    if (previous == null || previous.eventAt.isAfter(event.occurredAt)) {
      return false;
    }
    await entitlements.put(
      previous.withScheduledChange(scheduled, eventAt: event.occurredAt),
    );

    return true;
  }

  Future<bool> _applySubscription(
    SubscriptionState snapshot,
    DateTime occurredAt,
  ) async {
    final previous = await entitlements.bySubscription(snapshot.subscriptionId);
    if (previous != null && previous.eventAt.isAfter(occurredAt)) return false;
    await entitlements.put(snapshot.foldedOver(previous, occurredAt));

    return true;
  }
}
