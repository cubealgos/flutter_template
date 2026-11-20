// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:billing/billing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late InMemoryBillingLedger ledger;
  late InMemoryEntitlementStore store;
  late BillingEngine engine;

  setUp(() {
    ledger = InMemoryBillingLedger();
    store = InMemoryEntitlementStore();
    engine = BillingEngine(
      ledger: ledger,
      entitlements: store,
      clock: () => t0,
    );
  });

  test('a new event is recorded in the ledger and applied', () async {
    final outcome = await engine.process(
      event('evt_1', [LedgerChange.subscription(state())]),
    );

    expect(outcome.status, WebhookStatus.accepted);
    expect(outcome.recorded, 1);
    expect(outcome.applied, 1);
    expect(ledger.entries.single.key, 'evt_1');
    expect(ledger.entries.single.status, 'active');
    expect((await store.bySubscription('sub_1'))?.quantity, 3);
  });

  test(
    'a replayed event changes nothing: no row, no entitlement write',
    () async {
      final e = event('evt_1', [LedgerChange.subscription(state())]);
      await engine.process(e);
      final writes = store.writes;

      final replay = await engine.process(e);

      expect(replay.status, WebhookStatus.replayed);
      expect(replay.recorded, 0);
      expect(ledger.entries, hasLength(1));
      expect(store.writes, writes);
    },
  );

  test('a replay of an event whose first delivery changed the quantity does '
      'not undo a later change', () async {
    final first = event('evt_1', [LedgerChange.subscription(state())]);
    await engine.process(first);
    await engine.process(
      event('evt_2', [
        LedgerChange.subscription(
          state(quantity: 5, eventAt: t0.add(const Duration(hours: 1))),
        ),
      ], at: t0.add(const Duration(hours: 1))),
    );

    await engine.process(first);

    expect((await store.bySubscription('sub_1'))?.quantity, 5);
  });

  test(
    'when the ledger cannot be written the entitlement is not touched',
    () async {
      final broken = BillingEngine(
        ledger: FailingLedger(),
        entitlements: store,
      );

      await expectLater(
        broken.process(event('evt_1', [LedgerChange.subscription(state())])),
        throwsStateError,
      );

      expect(store.writes, 0);
    },
  );

  test('an event of several changes writes <id>#1, <id>#2; a redelivery '
      'after a partial write finishes the rest', () async {
    final changes = [
      LedgerChange.subscription(state()),
      LedgerChange.scheduledChange(
        subscriptionId: 'sub_1',
        change: ScheduledChange(
          action: ScheduledAction.cancel,
          effectiveAt: t0.add(const Duration(days: 10)),
        ),
      ),
    ];
    // The first delivery wrote only #1 (a crash after it).
    await ledger.append(
      LedgerEntry(
        key: 'evt_1#1',
        eventId: 'evt_1',
        eventType: 'subscription.updated',
        kind: LedgerKind.subscription,
        occurredAt: t0,
        receivedAt: t0,
        bodyHash: 'hash-evt_1',
        subscriptionId: 'sub_1',
      ),
    );

    final outcome = await engine.process(event('evt_1', changes));

    expect(outcome.recorded, 1);
    expect(ledger.entries.map((e) => e.key), <String>['evt_1#1', 'evt_1#2']);
  });

  test('an event with no effect is kept as a recorded row and changes no '
      'entitlement', () async {
    final outcome = await engine.process(
      event('evt_9', [
        const LedgerChange.recorded(detail: 'a payment'),
      ], type: 'transaction.completed'),
    );

    expect(outcome.recorded, 1);
    expect(outcome.applied, 0);
    expect(ledger.entries.single.kind, LedgerKind.recorded);
    expect(store.writes, 0);
  });

  test('an event older than the state is recorded and not applied', () async {
    await engine.process(
      event('evt_new', [
        LedgerChange.subscription(
          state(quantity: 5, eventAt: t0.add(const Duration(hours: 2))),
        ),
      ], at: t0.add(const Duration(hours: 2))),
    );

    final late = await engine.process(
      event('evt_old', [LedgerChange.subscription(state(quantity: 1))]),
    );

    expect(late.recorded, 1);
    expect(late.skipped, 1);
    expect((await store.bySubscription('sub_1'))?.quantity, 5);
  });

  test('a past-due subscription keeps its grace start across further '
      'past-due events and clears it on recovery', () async {
    final at1 = t0.add(const Duration(days: 1));
    final at2 = t0.add(const Duration(days: 2));
    final at3 = t0.add(const Duration(days: 3));
    await engine.process(
      event('e1', [
        LedgerChange.subscription(
          state(status: ProviderStatus.pastDue, eventAt: at1),
        ),
      ], at: at1),
    );
    await engine.process(
      event('e2', [
        LedgerChange.subscription(
          state(status: ProviderStatus.pastDue, eventAt: at2),
        ),
      ], at: at2),
    );
    expect((await store.bySubscription('sub_1'))?.pastDueSince, at1);

    await engine.process(
      event('e3', [LedgerChange.subscription(state(eventAt: at3))], at: at3),
    );

    expect((await store.bySubscription('sub_1'))?.pastDueSince, isNull);
  });

  test('a scheduled change updates only the scheduled change', () async {
    await engine.process(event('e1', [LedgerChange.subscription(state())]));
    final at = t0.add(const Duration(hours: 1));
    final cancel = ScheduledChange(
      action: ScheduledAction.cancel,
      effectiveAt: t0.add(const Duration(days: 9)),
    );

    await engine.process(
      event('e2', [
        LedgerChange.scheduledChange(subscriptionId: 'sub_1', change: cancel),
      ], at: at),
    );

    final stored = await store.bySubscription('sub_1');
    expect(stored?.scheduledChange, cancel);
    expect(stored?.quantity, 3);
    expect(stored?.eventAt, at);
  });
}
