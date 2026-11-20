// Test literals, `late` fixtures, `!` on a value the test just made and a
// do-nothing fake method are plain in a test.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name, solid_lints/no_empty_block, solid_lints/avoid_returning_widgets

import 'package:app/app/billing_owner_resolver.dart';
import 'package:app/app/router.dart';
import 'package:app/features/settings/paywall/paywall_controller.dart';
import 'package:billing/billing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';

import '../../../support/team_test_world.dart';

class _Navigation implements NavigationService {
  final List<String> pushed = <String>[];
  int pops = 0;
  bool canPopNow = false;

  @override
  void go(String location) {}

  @override
  Future<T?> push<T extends Object?>(String location) async {
    pushed.add(location);

    return null;
  }

  @override
  void pop<T extends Object?>([T? result]) => pops++;

  @override
  bool canPop() => canPopNow;

  @override
  Future<T?> replace<T extends Object?>(String location) async => null;
}

class _Launcher implements LauncherService {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> openUrl(Uri url, {bool external = false}) async {
    opened.add(url);

    return true;
  }

  @override
  Future<bool> canOpen(Uri url) async => true;
}

/// A [Billing] whose every call fails, as an offline or refusing server would.
class _FailingBilling implements Billing {
  @override
  Future<CheckoutSession> startCheckout({
    required String plan,
    required int quantity,
    required BillingOwner owner,
  }) async => throw const BillingProviderError('down');

  @override
  Future<PortalSession> openPortal(BillingOwner owner) async =>
      throw const BillingProviderError('down');

  @override
  Future<Entitlement> updateQuantity({
    required BillingOwner owner,
    required int quantity,
  }) async => throw const BillingProviderError('down');

  @override
  Future<Entitlement> entitlement(BillingOwner owner) async =>
      throw const BillingProviderError('down');
}

void main() {
  late TeamTestWorld world;
  late _Navigation navigation;
  late _Launcher launcher;

  setUp(() {
    world = TeamTestWorld();
    navigation = _Navigation();
    launcher = _Launcher();
  });

  Future<PaywallController> controller(
    Billing billing, {
    bool signedIn = true,
  }) async {
    if (signedIn) await world.ada.auth.restoreSession();
    final controller = PaywallController(
      navigation,
      billing,
      BillingOwnerResolver(world.ada.auth, world.ada.teams, world.ada.active),
      launcher,
    );
    // `init` starts the first load; wait for it by loading explicitly.
    await controller.refresh();

    return controller;
  }

  const owner = BillingOwner.user('ada-id');

  test('loads the entitlement: none for a new owner', () async {
    final c = await controller(FakeBilling());

    expect(c.value.loading, isFalse);
    expect(c.value.entitlement?.status, EntitlementStatus.none);
    expect(c.value.failed, isFalse);
  });

  test(
    'subscribe starts a checkout for the chosen quantity and opens it '
    'in the browser; after the (played) webhook, refresh shows access',
    () async {
      final billing = FakeBilling();
      final c = await controller(billing);
      c
        ..increase()
        ..increase();

      await c.subscribe();

      expect(c.value.quantity, 3);
      expect(launcher.opened.single.host, 'checkout.fake.invalid');
      final transaction = launcher.opened.single.queryParameters['_ptxn']!;
      await billing.completeCheckout(transaction);
      await c.refresh();
      expect(c.value.entitlement?.hasAccess, isTrue);
      expect(c.value.entitlement?.quantity, 3);
    },
  );

  test('applyQuantity changes the quantity, prorated; manage opens the '
      'portal', () async {
    final billing = FakeBilling();
    final session = await billing.startCheckout(
      plan: 'pro',
      quantity: 2,
      owner: owner,
    );
    await billing.completeCheckout(session.transactionId);
    final c = await controller(billing);
    expect(c.value.quantity, 2, reason: 'starts at what is paid for');

    c.increase();
    await c.applyQuantity();
    await c.manage();

    expect(c.value.entitlement?.quantity, 3);
    expect(billing.quantityChanges.single.prorated, isTrue);
    expect(launcher.opened.single.host, 'portal.fake.invalid');
  });

  test('the quantity never goes below one', () async {
    final c = await controller(FakeBilling());

    c
      ..decrease()
      ..decrease();

    expect(c.value.quantity, 1);
  });

  test('a failing server is a failed flag, not an exception', () async {
    final c = await controller(_FailingBilling());
    expect(c.value.failed, isTrue);
    expect(c.value.loading, isFalse);

    await c.subscribe();
    expect(c.value.failed, isTrue);
    expect(c.value.busy, isFalse);
    expect(launcher.opened, isEmpty);
  });

  test('nobody signed in: signedOut, and no call is made', () async {
    final c = await controller(FakeBilling(), signedIn: false);
    await c.subscribe();

    expect(c.value.signedOut, isTrue);
    expect(launcher.opened, isEmpty);
  });

  test(
    'legal links push the documents; goBack pops only when it can',
    () async {
      final c = await controller(FakeBilling());

      c
        ..openAgb()
        ..openDatenschutz()
        ..goBack();
      navigation.canPopNow = true;
      c.goBack();

      expect(navigation.pushed, <String>[
        const AgbRoute().location,
        const DatenschutzRoute().location,
      ]);
      expect(navigation.pops, 1);
    },
  );
}
