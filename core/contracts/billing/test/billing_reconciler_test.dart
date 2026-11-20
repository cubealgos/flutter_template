// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:billing/billing.dart';
import 'package:test/test.dart';

import 'support.dart';

class _Provider implements ProviderSubscriptions {
  _Provider(this.listed);

  final List<SubscriptionState> listed;

  @override
  Future<SubscriptionState?> fetch(
    String subscriptionId, {
    BillingOwner? knownOwner,
  }) async => null;

  @override
  Future<List<SubscriptionState>> list() async => listed;
}

void main() {
  late InMemoryBillingLedger ledger;
  late InMemoryEntitlementStore store;
  final later = t0.add(const Duration(hours: 5));

  setUp(() {
    ledger = InMemoryBillingLedger();
    store = InMemoryEntitlementStore();
  });

  BillingReconciler reconciler(_Provider provider) => BillingReconciler(
    provider: provider,
    entitlements: store,
    ledger: ledger,
    clock: () => later,
  );

  Future<void> seed({int quantity = 3}) async {
    final engine = BillingEngine(
      ledger: ledger,
      entitlements: store,
      clock: () => t0,
    );
    await engine.process(
      event('evt_1', [LedgerChange.subscription(state(quantity: quantity))]),
    );
  }

  test('corrects the entitlement from the provider, reports the divergence '
      'and leaves the ledger exactly as it was', () async {
    await seed();
    final before = ledger.entries.length;
    final provider = _Provider([
      state(quantity: 7, status: ProviderStatus.pastDue, eventAt: later),
    ]);

    final report = await reconciler(provider).run();

    final stored = await store.bySubscription('sub_1');
    expect(stored?.quantity, 7);
    expect(stored?.status, ProviderStatus.pastDue);
    expect(stored?.source, StateSource.reconciler);
    expect(
      report.divergences.map((d) => d.kind),
      containsAll(<DivergenceKind>[
        DivergenceKind.statusDiffers,
        DivergenceKind.quantityDiffers,
        DivergenceKind.ledgerBehind,
      ]),
    );
    expect(
      report.divergences
          .singleWhere((d) => d.kind == DivergenceKind.ledgerBehind)
          .corrected,
      isFalse,
    );
    expect(ledger.entries, hasLength(before));
  });

  test('a subscription the provider has and we never heard of is created and '
      'reported, with a note that the ledger has no row', () async {
    final report = await reconciler(_Provider([state()])).run();

    expect(await store.bySubscription('sub_1'), isNotNull);
    expect(
      report.divergences.map((d) => d.kind),
      containsAll(<DivergenceKind>[
        DivergenceKind.missingEntitlement,
        DivergenceKind.notInLedger,
      ]),
    );
    expect(ledger.entries, isEmpty);
  });

  test(
    'agreement reports nothing and writes nothing but the compared-at time',
    () async {
      await seed();

      final report = await reconciler(_Provider([state()])).run();

      expect(report.divergences, isEmpty);
      expect(report.checked, 1);
      expect((await store.bySubscription('sub_1'))?.reconciledAt, later);
    },
  );

  test('a known subscription missing from the listing is fetched by ID; one '
      'the provider denies is reported and kept', () async {
    await seed();

    final report = await reconciler(_Provider([])).run();

    expect(report.divergences.single.kind, DivergenceKind.unknownToProvider);
    expect(report.divergences.single.corrected, isFalse);
    expect(await store.bySubscription('sub_1'), isNotNull);
  });

  test('a correction never moves eventAt backwards', () async {
    await seed();
    final newer = state(quantity: 4, eventAt: t0.add(const Duration(days: 9)));
    await store.put(newer);

    await reconciler(_Provider([state(quantity: 9)])).run();

    final stored = await store.bySubscription('sub_1');
    expect(stored?.quantity, 9);
    expect(stored?.eventAt, t0.add(const Duration(days: 9)));
  });
}
