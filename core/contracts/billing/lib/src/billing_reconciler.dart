// The comparison reads many members of the states it compares.
// ignore_for_file: solid_lints/feature_envy

import 'package:billing/src/billing_ledger_reader.dart';
import 'package:billing/src/divergence.dart';
import 'package:billing/src/divergence_kind.dart';
import 'package:billing/src/entitlement_store.dart';
import 'package:billing/src/ledger_kind.dart';
import 'package:billing/src/provider_subscriptions.dart';
import 'package:billing/src/reconcile_report.dart';
import 'package:billing/src/subscription_state.dart';

/// Compares the provider's view of each subscription (status, quantity, plan)
/// with the ledger and the entitlement.
///
/// It **corrects the entitlement from the provider's data** and **reports every
/// divergence**. It **never writes the ledger**: it is given only a
/// `BillingLedgerReader`, so it cannot. A correction keeps a past-due
/// subscription's `pastDueSince` and never moves `eventAt` backwards, so a
/// late provider event older than the correction is not applied over it.
class BillingReconciler {
  /// Creates a reconciler.
  BillingReconciler({
    required this.provider,
    required this.entitlements,
    required this.ledger,
    DateTime Function()? clock,
    this.batch = 100,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  /// The provider's own view.
  final ProviderSubscriptions provider;

  /// The entitlements it corrects.
  final EntitlementStore entitlements;

  /// The ledger, **read-only**: the reconciler cannot write it.
  final BillingLedgerReader ledger;

  /// How many known subscriptions a run compares individually.
  final int batch;

  final DateTime Function() _clock;

  /// Runs one comparison.
  Future<ReconcileReport> run() async {
    final divergences = <Divergence>[];
    final seen = <String>{};
    var checked = 0;

    // What the provider lists, including subscriptions we never heard of.
    for (final theirs in await provider.list()) {
      seen.add(theirs.subscriptionId);
      checked++;
      await _compare(
        theirs,
        await entitlements.bySubscription(theirs.subscriptionId),
        divergences,
      );
    }
    // What we know and the listing did not contain: ask for it by ID.
    for (final ours in await entitlements.dueForReconciliation(batch)) {
      if (!seen.add(ours.subscriptionId)) continue;
      checked++;
      final theirs = await provider.fetch(
        ours.subscriptionId,
        knownOwner: ours.owner,
      );
      if (theirs == null) {
        divergences.add(
          Divergence(
            subscriptionId: ours.subscriptionId,
            kind: DivergenceKind.unknownToProvider,
            detail: 'entitlement is ${ours.status.wire}, provider has none',
            corrected: false,
          ),
        );
        continue;
      }
      await _compare(theirs, ours, divergences);
    }

    return ReconcileReport(checked: checked, divergences: divergences);
  }

  Future<void> _compare(
    SubscriptionState theirs,
    SubscriptionState? ours,
    List<Divergence> out,
  ) async {
    final id = theirs.subscriptionId;
    if (ours == null) {
      out.add(
        Divergence(
          subscriptionId: id,
          kind: DivergenceKind.missingEntitlement,
          detail:
              'provider: ${theirs.status.wire} x${theirs.quantity} '
              '${theirs.plan}',
          corrected: true,
        ),
      );
      await _correct(theirs, null);
    } else {
      final kinds = <DivergenceKind, String>{
        if (ours.status != theirs.status)
          DivergenceKind.statusDiffers:
              'entitlement ${ours.status.wire}, provider ${theirs.status.wire}',
        if (ours.quantity != theirs.quantity)
          DivergenceKind.quantityDiffers:
              'entitlement ${ours.quantity}, provider ${theirs.quantity}',
        if (ours.plan != theirs.plan)
          DivergenceKind.planDiffers:
              'entitlement ${ours.plan}, provider ${theirs.plan}',
      };
      for (final entry in kinds.entries) {
        out.add(
          Divergence(
            subscriptionId: id,
            kind: entry.key,
            detail: entry.value,
            corrected: true,
          ),
        );
      }
      if (kinds.isNotEmpty) {
        await _correct(theirs, ours);
      } else {
        // Compared and equal: record when, so the next run takes others first.
        await entitlements.put(ours.reconciledAtTime(_clock()));
      }
    }
    await _compareLedger(theirs, out);
  }

  Future<void> _compareLedger(
    SubscriptionState theirs,
    List<Divergence> out,
  ) async {
    final id = theirs.subscriptionId;
    final rows = (await ledger.forSubscription(
      id,
    )).where((e) => e.kind == LedgerKind.subscription).toList();
    if (rows.isEmpty) {
      out.add(
        Divergence(
          subscriptionId: id,
          kind: DivergenceKind.notInLedger,
          detail: 'no ledger row; the provider says ${theirs.status.wire}',
          corrected: false,
        ),
      );

      return;
    }
    final latest = rows.last;
    if (latest.status != theirs.status.wire ||
        latest.quantity != theirs.quantity) {
      out.add(
        Divergence(
          subscriptionId: id,
          kind: DivergenceKind.ledgerBehind,
          detail:
              'ledger ${latest.status} x${latest.quantity}, provider '
              '${theirs.status.wire} x${theirs.quantity}',
          corrected: false,
        ),
      );
    }
  }

  Future<void> _correct(SubscriptionState theirs, SubscriptionState? ours) =>
      entitlements.put(theirs.correctionOf(ours, _clock()));
}
