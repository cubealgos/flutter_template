// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:billing/billing.dart';

/// A fixed point in time the tests count from.
final DateTime t0 = DateTime.utc(2026, 10, 1, 12);

/// [BillingOwner] of the tests.
const BillingOwner team = BillingOwner.team('team1');

/// A subscription state for [team].
SubscriptionState state({
  DateTime? eventAt,
  ScheduledChange? scheduled,
  DateTime? nextBilledAt,
  String id = 'sub_1',
  ProviderStatus status = ProviderStatus.active,
  int quantity = 3,
  String plan = 'pro',
}) => SubscriptionState(
  subscriptionId: id,
  customerId: 'ctm_1',
  owner: team,
  plan: plan,
  quantity: quantity,
  status: status,
  eventAt: eventAt ?? t0,
  nextBilledAt: nextBilledAt ?? t0.add(const Duration(days: 30)),
  scheduledChange: scheduled,
);

/// An event of [changes] with the ID [id].
ProviderEvent event(
  String id,
  List<LedgerChange> changes, {
  DateTime? at,
  String type = 'subscription.updated',
}) => ProviderEvent(
  id: id,
  type: type,
  occurredAt: at ?? t0,
  bodyHash: 'hash-$id',
  changes: changes,
);

/// A ledger whose `append` always fails, as a down database would.
class FailingLedger extends InMemoryBillingLedger {
  @override
  Future<bool> append(LedgerEntry entry) async =>
      throw StateError('ledger down');
}
