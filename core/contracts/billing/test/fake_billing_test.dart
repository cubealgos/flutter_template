// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:billing/billing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late DateTime now;
  late FakeBilling billing;

  setUp(() {
    now = t0;
    billing = FakeBilling(plans: {'pro'}, clock: () => now);
  });

  test('checkout, then the (played) webhook, then an entitlement', () async {
    final session = await billing.startCheckout(
      plan: 'pro',
      quantity: 2,
      owner: team,
    );
    expect((await billing.entitlement(team)).hasAccess, isFalse);

    await billing.completeCheckout(session.transactionId);

    final e = await billing.entitlement(team);
    expect(e.hasAccess, isTrue);
    expect(e.quantity, 2);
  });

  test('quantity updates are prorated and recorded; the portal needs a '
      'subscription', () async {
    await expectLater(
      billing.openPortal(team),
      throwsA(isA<BillingNoSubscriptionError>()),
    );
    final s = await billing.startCheckout(
      plan: 'pro',
      quantity: 1,
      owner: team,
    );
    await billing.completeCheckout(s.transactionId);

    final e = await billing.updateQuantity(owner: team, quantity: 4);

    expect(e.quantity, 4);
    expect(billing.quantityChanges.single.prorated, isTrue);
    expect((await billing.openPortal(team)).url.host, 'portal.fake.invalid');
  });

  test('rejects an unknown plan and a quantity below one', () async {
    await expectLater(
      billing.startCheckout(plan: 'gold', quantity: 1, owner: team),
      throwsA(isA<BillingUnknownPlanError>()),
    );
    await expectLater(
      billing.startCheckout(plan: 'pro', quantity: 0, owner: team),
      throwsA(isA<BillingInvalidError>()),
    );
  });

  test(
    'past due keeps access through the grace period and then ends it',
    () async {
      final s = await billing.startCheckout(
        plan: 'pro',
        quantity: 1,
        owner: team,
      );
      await billing.completeCheckout(s.transactionId);
      await billing.markPastDue(team);

      expect((await billing.entitlement(team)).hasAccess, isTrue);
      now = t0.add(const Duration(days: 8));
      expect(
        (await billing.entitlement(team)).status,
        EntitlementStatus.expired,
      );
    },
  );

  test('the wire round-trips an entitlement and maps an error body', () {
    final e = state(status: ProviderStatus.pastDue).entitlementAt(t0);

    final back = BillingWire.entitlementFromJson(
      BillingWire.entitlementToJson(e),
    );

    expect(back, e);
    expect(
      BillingWire.errorFromJson(
        403,
        BillingWire.errorToJson(const BillingForbiddenError('no')),
      ),
      isA<BillingForbiddenError>(),
    );
  });
}
