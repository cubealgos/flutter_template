// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:billing/billing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const policy = EntitlementPolicy(grace: Duration(days: 10));

  test('an active subscription has access and a renewal', () {
    final e = state().entitlementAt(t0, policy);

    expect(e.status, EntitlementStatus.active);
    expect(e.hasAccess, isTrue);
    expect(e.quantity, 3);
    expect(e.plan, 'pro');
    expect(e.renewsAt, t0.add(const Duration(days: 30)));
  });

  test('past due: access during the grace period, none after it, with no '
      'event in between - the clock alone decides', () {
    final s = state(status: ProviderStatus.pastDue).copyForTest(since: t0);

    final during = s.entitlementAt(t0.add(const Duration(days: 9)), policy);
    final after = s.entitlementAt(t0.add(const Duration(days: 10)), policy);

    expect(during.status, EntitlementStatus.pastDue);
    expect(during.hasAccess, isTrue);
    expect(during.graceEndsAt, t0.add(const Duration(days: 10)));
    expect(after.status, EntitlementStatus.expired);
    expect(after.hasAccess, isFalse);
  });

  test('a scheduled cancellation keeps access until it takes effect', () {
    final cancelAt = t0.add(const Duration(days: 5));
    final s = state(
      scheduled: ScheduledChange(
        action: ScheduledAction.cancel,
        effectiveAt: cancelAt,
      ),
    );

    final before = s.entitlementAt(t0.add(const Duration(days: 4)), policy);
    final after = s.entitlementAt(cancelAt, policy);

    expect(before.hasAccess, isTrue);
    expect(before.cancelsAt, cancelAt);
    expect(before.renewsAt, isNull);
    expect(after.status, EntitlementStatus.canceled);
    expect(after.hasAccess, isFalse);
  });

  test('canceled and paused subscriptions have no access', () {
    expect(
      state(status: ProviderStatus.canceled).entitlementAt(t0).hasAccess,
      isFalse,
    );
    expect(
      state(status: ProviderStatus.paused).entitlementAt(t0).status,
      EntitlementStatus.paused,
    );
  });

  test('the reader prefers a subscription with access over a newer ended '
      'one, and answers none for an owner with nothing', () async {
    final store = InMemoryEntitlementStore();
    await store.put(state(id: 'sub_old', eventAt: t0));
    await store.put(
      state(
        id: 'sub_new',
        status: ProviderStatus.canceled,
        eventAt: t0.add(const Duration(days: 1)),
      ),
    );
    final reader = EntitlementReader(store: store, clock: () => t0);

    final e = await reader.forOwner(team);
    final none = await reader.forOwner(const BillingOwner.user('nobody'));

    expect(e.hasAccess, isTrue);
    expect(none.status, EntitlementStatus.none);
    expect(none.hasAccess, isFalse);
  });

  test('BillingOwner round-trips through its key', () {
    expect(BillingOwner.tryParse('team:abc'), const BillingOwner.team('abc'));
    expect(BillingOwner.tryParse('user:u1')?.kind, BillingOwnerKind.user);
    expect(BillingOwner.tryParse('abc'), isNull);
    expect(BillingOwner.tryParse('org:abc'), isNull);
    expect(BillingOwner.tryParse('team:'), isNull);
  });
}

extension on SubscriptionState {
  SubscriptionState copyForTest({required DateTime since}) =>
      foldedOver(null, since);
}
