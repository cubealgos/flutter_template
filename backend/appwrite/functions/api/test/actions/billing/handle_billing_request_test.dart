// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

import 'package:api/src/actions/billing/handle_billing_request.dart';
import 'package:billing/billing.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paddle_billing/paddle_billing.dart';
import 'package:test/test.dart';

class _Access implements BillingAccess {
  bool allow = true;

  @override
  Future<bool> mayManage(String userId, BillingOwner owner) async => allow;

  @override
  Future<bool> mayRead(String userId, BillingOwner owner) async => allow;
}

void main() {
  late InMemoryEntitlementStore store;
  late _Access access;
  final now = DateTime.utc(2026, 10, 2);
  final paddleCalls = <String>[];

  BillingService service() => BillingService(
    access: access,
    entitlements: store,
    plans: const PaddlePlans(<String, String>{'pro': 'pri_pro'}),
    policy: const EntitlementPolicy(),
    clock: () => now,
    api: PaddleApi(
      httpClient: MockClient((request) async {
        paddleCalls.add('${request.method} ${request.url.path}');

        return await Future.value(
          http.Response(
            jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'id': 'txn_1',
                'checkout': <String, dynamic>{
                  'url': 'https://pay.example.test/x',
                },
              },
            }),
            201,
          ),
        );
      }),
      key: 'pdl_sdbx_apikey_x',
    ),
  );

  Future<Map<String, dynamic>> call(
    Map<String, dynamic> body, {
    String caller = 'u1',
    Set<String> workers = const <String>{},
  }) async {
    final response = await handleBillingRequest(
      callerUserId: caller,
      workerUserIds: workers,
      body: body,
      service: service(),
    );

    return <String, dynamic>{...response.body, '_status': response.statusCode};
  }

  setUp(() {
    store = InMemoryEntitlementStore();
    access = _Access();
    paddleCalls.clear();
  });

  Future<void> subscribe(String owner) => store.put(
    SubscriptionState(
      subscriptionId: 'sub_1',
      customerId: 'ctm_1',
      owner: BillingOwner.tryParse(owner)!,
      plan: 'pro',
      quantity: 4,
      status: ProviderStatus.active,
      eventAt: now,
    ),
  );

  test("start_checkout for the caller's own user by default", () async {
    final answer = await call(<String, dynamic>{
      'op': 'start_checkout',
      'plan': 'pro',
      'quantity': 2,
    });

    expect(answer['_status'], 200);
    expect(answer['transactionId'], 'txn_1');
    expect(paddleCalls, <String>['POST /transactions']);
  });

  test(
    'entitlement of a team, answered from the stored state and the clock',
    () async {
      await subscribe('team:t1');

      final answer = await call(<String, dynamic>{
        'op': 'entitlement',
        'owner': 'team:t1',
      });

      expect(answer['hasAccess'], isTrue);
      expect(answer['quantity'], 4);
      expect(answer['status'], 'active');
    },
  );

  test(
    'a caller who may not act for the owner gets 403 with a stable code',
    () async {
      access.allow = false;

      final answer = await call(<String, dynamic>{
        'op': 'start_checkout',
        'plan': 'pro',
        'quantity': 1,
        'owner': 'team:t1',
      });

      expect(answer['_status'], 403);
      expect((answer['error'] as Map)['code'], 'forbidden');
      expect(paddleCalls, isEmpty);
    },
  );

  test(
    'validation: owner, plan, quantity and unknown operations are 400',
    () async {
      for (final body in <Map<String, dynamic>>[
        {
          'op': 'start_checkout',
          'plan': 'pro',
          'quantity': 1,
          'owner': 'org:1',
        },
        {'op': 'start_checkout', 'quantity': 1},
        {'op': 'start_checkout', 'plan': 'pro', 'quantity': 0},
        {'op': 'start_checkout', 'plan': 'pro', 'quantity': '2'},
        {'op': 'update_quantity', 'quantity': 1.5},
        {'op': 'nope'},
        <String, dynamic>{},
      ]) {
        expect((await call(body))['_status'], 400, reason: '$body');
      }
    },
  );

  test('entitlement_of is for configured workers only', () async {
    await subscribe('team:t1');
    final body = <String, dynamic>{'op': 'entitlement_of', 'owner': 'team:t1'};

    expect((await call(body))['_status'], 403);
    final worker = await call(body, caller: 'w1', workers: {'w1'});
    expect(worker['_status'], 200);
    expect(worker['hasAccess'], isTrue);
  });

  test('an unknown plan is a 400 unknown_plan', () async {
    final answer = await call(<String, dynamic>{
      'op': 'start_checkout',
      'plan': 'gold',
      'quantity': 1,
    });

    expect(answer['_status'], 400);
    expect((answer['error'] as Map)['code'], 'unknown_plan');
  });
}
