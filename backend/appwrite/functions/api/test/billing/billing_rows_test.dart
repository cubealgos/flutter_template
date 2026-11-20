// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:api/billing_stores.dart';
import 'package:billing/billing.dart';
import 'package:test/test.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1, 12);

  test('a ledger row ID is a valid Appwrite row ID and the same for the same '
      'key, so a second append of one key collides', () {
    final id = ledgerRowId('evt_01h#2');

    expect(id, matches(RegExp(r'^[A-Za-z0-9_]{1,36}$')));
    expect(ledgerRowId('evt_01h#2'), id);
    expect(ledgerRowId('evt_01h#1'), isNot(id));
  });

  test('an entitlement row ID is the subscription id when it is a valid ID, '
      'else a hash of it', () {
    expect(
      entitlementRowId('sub_01h2xcejqtf2nbrexx3vqjhp41'),
      'sub_01h2xcejqtf2nbrexx3vqjhp41',
    );
    expect(entitlementRowId('a#b'), matches(RegExp(r'^[A-Za-z0-9_]{1,36}$')));
    expect(entitlementRowId('x' * 50), hasLength(36));
  });

  test('a ledger entry round-trips through its row', () {
    final entry = LedgerEntry(
      key: 'evt_1#1',
      eventId: 'evt_1',
      eventType: 'subscription.updated',
      kind: LedgerKind.subscription,
      occurredAt: t,
      receivedAt: t,
      bodyHash: 'ab' * 32,
      subscriptionId: 'sub_1',
      ownerKey: 'team:t1',
      status: 'active',
      quantity: 3,
      plan: 'pro',
    );

    final back = ledgerEntryFromRow(ledgerRowData(entry))!;

    expect(back.key, entry.key);
    expect(back.kind, LedgerKind.subscription);
    expect(back.quantity, 3);
    expect(back.occurredAt, t);
    expect(ledgerRowData(entry), isNot(contains('detail')));
    expect(ledgerRowData(entry).keys, isNot(contains('payload')));
  });

  test('a state round-trips through its row, scheduled change included, and '
      'writes nulls so a cleared value is cleared', () {
    final state = SubscriptionState(
      subscriptionId: 'sub_1',
      customerId: 'ctm_1',
      owner: const BillingOwner.team('t1'),
      plan: 'pro',
      quantity: 3,
      status: ProviderStatus.pastDue,
      pastDueSince: t,
      scheduledChange: ScheduledChange(
        action: ScheduledAction.cancel,
        effectiveAt: t.add(const Duration(days: 3)),
      ),
      eventAt: t,
      source: StateSource.reconciler,
    );

    final data = stateRowData(state, t);
    final back = stateFromRow(data)!;

    expect(back.owner, state.owner);
    expect(back.status, ProviderStatus.pastDue);
    expect(back.pastDueSince, t);
    expect(back.scheduledChange, state.scheduledChange);
    expect(back.source, StateSource.reconciler);
    expect(data.containsKey('canceledAt'), isTrue);
    expect(data['canceledAt'], isNull);
    expect(stateFromRow(<String, dynamic>{'status': 'bogus'}), isNull);
  });
}
