// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

import 'package:billing/billing.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paddle_billing/paddle_billing.dart';
import 'package:test/test.dart';

import 'support.dart';

class _Access implements BillingAccess {
  bool manage = true;
  bool read = true;

  @override
  Future<bool> mayManage(String userId, BillingOwner owner) async => manage;

  @override
  Future<bool> mayRead(String userId, BillingOwner owner) async => read;
}

void main() {
  const owner = BillingOwner.team('team1');
  final now = DateTime.utc(2026, 10, 2);
  final calls = <String>[];
  late InMemoryEntitlementStore store;
  late _Access access;

  BillingService service({bool configured = true}) {
    calls.clear();
    final api = PaddleApi(
      httpClient: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        final entity = subscriptionEntity(quantity: 8);
        final data = switch (request.url.path) {
          '/transactions' => <String, dynamic>{
            'id': 'txn_1',
            'checkout': <String, dynamic>{'url': 'https://pay.example.test/x'},
          },
          '/customers/ctm_01/portal-sessions' => <String, dynamic>{
            'urls': <String, dynamic>{
              'general': <String, dynamic>{
                'overview': 'https://portal.example.test',
              },
            },
          },
          _ => entity,
        };

        return http.Response(jsonEncode(<String, dynamic>{'data': data}), 200);
      }),
      key: 'pdl_sdbx_apikey_x',
    );

    return BillingService(
      access: access,
      entitlements: store,
      plans: const PaddlePlans(<String, String>{'pro': 'pri_pro'}),
      policy: const EntitlementPolicy(),
      api: configured ? api : null,
      clock: () => now,
    );
  }

  Future<void> subscribed() => store.put(
    SubscriptionState(
      subscriptionId: 'sub_01',
      customerId: 'ctm_01',
      owner: owner,
      plan: 'pro',
      quantity: 3,
      status: ProviderStatus.active,
      eventAt: now,
    ),
  );

  setUp(() {
    store = InMemoryEntitlementStore();
    access = _Access();
  });

  test(
    'a checkout is refused for a caller who may not manage the owner, '
    'for an unknown plan and for a bad quantity - before any Paddle call',
    () async {
      access.manage = false;
      await expectLater(
        service().startCheckout(
          caller: 'u',
          plan: 'pro',
          quantity: 1,
          owner: owner,
        ),
        throwsA(isA<BillingForbiddenError>()),
      );
      access.manage = true;
      await expectLater(
        service().startCheckout(
          caller: 'u',
          plan: 'gold',
          quantity: 1,
          owner: owner,
        ),
        throwsA(isA<BillingUnknownPlanError>()),
      );
      await expectLater(
        service().startCheckout(
          caller: 'u',
          plan: 'pro',
          quantity: 0,
          owner: owner,
        ),
        throwsA(isA<BillingInvalidError>()),
      );
      expect(calls, isEmpty);
    },
  );

  test('a checkout for an owner with access is refused; otherwise it calls '
      'Paddle', () async {
    final s = service();
    final session = await s.startCheckout(
      caller: 'u',
      plan: 'pro',
      quantity: 2,
      owner: owner,
    );
    expect(session.transactionId, 'txn_1');
    expect(calls, <String>['POST /transactions']);

    await subscribed();
    await expectLater(
      s.startCheckout(caller: 'u', plan: 'pro', quantity: 2, owner: owner),
      throwsA(isA<BillingInvalidError>()),
    );
  });

  test('updateQuantity changes the quantity at Paddle, prorated, and writes '
      'no entitlement', () async {
    await subscribed();
    final writes = store.writes;

    final e = await service().updateQuantity(
      caller: 'u',
      owner: owner,
      quantity: 8,
    );

    expect(calls, <String>[
      'GET /subscriptions/sub_01',
      'PATCH /subscriptions/sub_01',
    ]);
    expect(e.quantity, 8);
    expect(
      store.writes,
      writes,
      reason: 'the webhook stores it, not this call',
    );
  });

  test('the portal needs a subscription and a customer', () async {
    await expectLater(
      service().openPortal(caller: 'u', owner: owner),
      throwsA(isA<BillingNoSubscriptionError>()),
    );
    await subscribed();

    final session = await service().openPortal(caller: 'u', owner: owner);

    expect(session.url.host, 'portal.example.test');
  });

  test('no API key means BillingNotConfiguredError, and entitlement still '
      'reads', () async {
    await subscribed();
    final s = service(configured: false);

    await expectLater(
      s.openPortal(caller: 'u', owner: owner),
      throwsA(isA<BillingNotConfiguredError>()),
    );
    expect((await s.entitlement(caller: 'u', owner: owner)).hasAccess, isTrue);
  });

  test('reading needs mayRead', () async {
    access.read = false;

    await expectLater(
      service().entitlement(caller: 'u', owner: owner),
      throwsA(isA<BillingForbiddenError>()),
    );
  });

  test('config: parses the variables and rejects a malformed number', () {
    final config = PaddleConfig.fromEnvironment(<String, String>{
      'PADDLE_PLANS': '{"pro":"pri_pro"}',
      'BILLING_GRACE_DAYS': '14',
      'PADDLE_WEBHOOK_SECRET': 'secret',
    });

    expect(config.plans.priceFor('pro'), 'pri_pro');
    expect(config.policy.grace, const Duration(days: 14));
    expect(config.webhookSecret, 'secret');
    expect(config.apiKey, isNull);
    expect(
      () => PaddleConfig.fromEnvironment(<String, String>{
        'BILLING_GRACE_DAYS': 'x',
      }),
      throwsFormatException,
    );
  });
}
