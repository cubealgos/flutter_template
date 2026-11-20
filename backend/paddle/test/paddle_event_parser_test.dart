// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

import 'package:billing/billing.dart';
import 'package:paddle_billing/paddle_billing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final parser = PaddleEventParser(
    const PaddlePlans(<String, String>{'pro': 'pri_pro'}),
  );

  ProviderEvent parse(String body) => parser.parse(utf8.encode(body));

  test(
    'every subscription event is a state change plus a scheduled change',
    () {
      for (final type in <String>[
        'subscription.created',
        'subscription.activated',
        'subscription.updated',
        'subscription.trialing',
        'subscription.past_due',
        'subscription.paused',
        'subscription.resumed',
        'subscription.canceled',
      ]) {
        final event = parse(subscriptionEvent(type: type));

        expect(event.changes.map((c) => c.kind), <LedgerKind>[
          LedgerKind.subscription,
          LedgerKind.scheduledChange,
        ], reason: type);
      }
    },
  );

  test('reads plan, quantity, status, owner and the dates from the entity', () {
    final event = parse(
      subscriptionEvent(status: 'past_due', quantity: 5, owner: 'user:u1'),
    );

    final state = event.changes.first.state;
    expect(event.id, 'evt_01');
    expect(event.type, 'subscription.updated');
    expect(event.occurredAt, DateTime.utc(2026, 10, 1, 12));
    expect(state?.plan, 'pro');
    expect(state?.quantity, 5);
    expect(state?.status, ProviderStatus.pastDue);
    expect(state?.owner, const BillingOwner.user('u1'));
    expect(state?.customerId, 'ctm_01');
    expect(state?.nextBilledAt, DateTime.utc(2026, 11, 1, 12));
    expect(event.bodyHash, hasLength(64));
  });

  test('a scheduled cancellation travels in its own change', () {
    final event = parse(
      subscriptionEvent(
        scheduledChange: <String, dynamic>{
          'action': 'cancel',
          'effective_at': '2026-11-01T12:00:00Z',
          'resume_at': null,
        },
      ),
    );

    expect(
      event.changes.last.scheduled,
      ScheduledChange(
        action: ScheduledAction.cancel,
        effectiveAt: DateTime.utc(2026, 11, 1, 12),
      ),
    );
  });

  test(
    'a price that is not in the plan list keeps its price id as the plan',
    () {
      final event = parse(subscriptionEvent(priceId: 'pri_unlisted'));

      expect(event.changes.first.state?.plan, 'pri_unlisted');
    },
  );

  test('a non-subscription event is one recorded row', () {
    final event = parse(
      jsonEncode(<String, dynamic>{
        'event_id': 'evt_tx',
        'event_type': 'transaction.completed',
        'occurred_at': '2026-10-01T12:00:00Z',
        'notification_id': 'ntf_1',
        'data': <String, dynamic>{'id': 'txn_1', 'subscription_id': 'sub_01'},
      }),
    );

    expect(event.changes, hasLength(1));
    expect(event.changes.single.kind, LedgerKind.recorded);
    expect(event.changes.single.subscriptionId, 'sub_01');
  });

  test('a subscription with no owner in custom_data is recorded, not '
      'applied', () {
    final event = parse(subscriptionEvent(owner: null));

    expect(event.changes.single.kind, LedgerKind.recorded);
    expect(event.changes.single.detail, contains('no owner'));
  });

  test('a body that is not what Paddle documents throws', () {
    expect(() => parse('nope'), throwsA(isA<PaddleParseException>()));
    expect(() => parse('[]'), throwsA(isA<PaddleParseException>()));
    expect(
      () => parse('{"event_type":"x"}'),
      throwsA(isA<PaddleParseException>()),
    );
  });

  test('through the engine: two changes, ids evt_01#1 and #2, and a replay '
      'of the body changes nothing', () async {
    final ledger = InMemoryBillingLedger();
    final store = InMemoryEntitlementStore();
    final engine = BillingEngine(ledger: ledger, entitlements: store);
    final body = subscriptionEvent(status: 'trialing');

    await engine.process(parse(body));
    final writes = store.writes;
    final replay = await engine.process(parse(body));

    expect(ledger.entries.map((e) => e.key), <String>['evt_01#1', 'evt_01#2']);
    expect(replay.status, WebhookStatus.replayed);
    expect(store.writes, writes);
  });
}
