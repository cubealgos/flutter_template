// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:api/src/actions/billing/billing_reconciler_job.dart';
import 'package:billing/billing.dart';
import 'package:test/test.dart';

import '../../support/test_context.dart';

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
  final t = DateTime.utc(2026, 10, 1, 12);
  SubscriptionState state(int quantity) => SubscriptionState(
    subscriptionId: 'sub_1',
    owner: const BillingOwner.team('t1'),
    plan: 'pro',
    quantity: quantity,
    status: ProviderStatus.active,
    eventAt: t,
  );

  test('does nothing, and says so, while no API key is set', () async {
    final logs = <String>[];

    await const BillingReconcilerJob().run(testContext(logs: logs), slot: 1);

    expect(logs.single, contains('PADDLE_API_KEY is not set'));
  });

  test(
    'logs every divergence and a summary; the entitlement is corrected',
    () async {
      final logs = <String>[];
      final store = InMemoryEntitlementStore();
      await store.put(state(2));
      final job = BillingReconcilerJob(
        reconcilerFor: (_, _) => BillingReconciler(
          provider: _Provider([state(5)]),
          entitlements: store,
          ledger: InMemoryBillingLedger(),
        ),
      );

      await job.run(testContext(logs: logs), slot: 1);

      expect((await store.bySubscription('sub_1'))?.quantity, 5);
      expect(logs.any((l) => l.contains('quantityDiffers')), isTrue);
      expect(logs.any((l) => l.contains('notInLedger')), isTrue);
      expect(logs.last, contains('2 divergence(s)'));
    },
  );
}
