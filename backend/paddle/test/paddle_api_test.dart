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

void main() {
  const sandboxKey =
      'pdl_sdbx_apikey_01gtgztp8f4kek3yd4g1wrksa3_q6TGTJyvoIz7LDtXT65_AQO';
  final requests = <http.Request>[];

  PaddleApi api(
    Future<http.Response> Function(http.Request) respond, {
    String key = sandboxKey,
  }) {
    requests.clear();

    return PaddleApi(
      httpClient: MockClient((request) async {
        requests.add(request);

        return await respond(request);
      }),
      key: key,
    );
  }

  http.Response ok(Object data, [int status = 200]) => http.Response(
    jsonEncode(<String, dynamic>{'data': data}),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  test('the key decides sandbox or live; an unknown key shape is refused', () {
    expect(
      paddleBaseFor('pdl_sdbx_apikey_x'),
      'https://sandbox-api.paddle.com',
    );
    expect(paddleBaseFor('pdl_live_apikey_x'), 'https://api.paddle.com');
    expect(
      () => paddleBaseFor('0123456789abcdef'),
      throwsA(isA<PaddleApiException>()),
    );
  });

  test('createTransaction: POST /transactions with the item, the owner in '
      'custom_data and a bearer key; returns checkout.url', () async {
    final client = api(
      (_) async => ok(<String, dynamic>{
        'id': 'txn_01',
        'checkout': <String, dynamic>{
          'url': 'https://pay.example.test/?_ptxn=txn_01',
        },
      }, 201),
    );

    final session = await client.createTransaction(
      priceId: 'pri_pro',
      quantity: 4,
      owner: const BillingOwner.team('team1'),
    );

    final request = requests.single;
    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'https://sandbox-api.paddle.com/transactions',
    );
    expect(request.headers['Authorization'], 'Bearer $sandboxKey');
    expect(jsonDecode(request.body), <String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'price_id': 'pri_pro', 'quantity': 4},
      ],
      'custom_data': <String, dynamic>{'owner': 'team:team1'},
    });
    expect(session.transactionId, 'txn_01');
    expect(session.url.host, 'pay.example.test');
  });

  test('updateQuantity: reads the subscription, then PATCHes every item with '
      'the new quantity and prorated_immediately', () async {
    final entity = subscriptionEntity();
    (entity['items'] as List).add(<String, dynamic>{
      'status': 'active',
      'quantity': 1,
      'price': <String, dynamic>{'id': 'pri_addon'},
    });
    final client = api((_) async => ok(entity));

    await client.updateQuantity(
      subscriptionId: 'sub_01',
      priceId: 'pri_pro',
      quantity: 9,
    );

    expect(requests.map((r) => r.method), <String>['GET', 'PATCH']);
    expect(requests.last.url.path, '/subscriptions/sub_01');
    expect(jsonDecode(requests.last.body), <String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'price_id': 'pri_pro', 'quantity': 9},
        <String, dynamic>{'price_id': 'pri_addon', 'quantity': 1},
      ],
      'proration_billing_mode': 'prorated_immediately',
    });
  });

  test('createPortalSession: POST /customers/{id}/portal-sessions, returns '
      'urls.general.overview', () async {
    final client = api(
      (_) async => ok(<String, dynamic>{
        'urls': <String, dynamic>{
          'general': <String, dynamic>{
            'overview': 'https://portal.example.test/o',
          },
        },
      }, 201),
    );

    final url = await client.createPortalSession(
      customerId: 'ctm_01',
      subscriptionIds: <String>['sub_01'],
    );

    expect(requests.single.url.path, '/customers/ctm_01/portal-sessions');
    expect(jsonDecode(requests.single.body), <String, dynamic>{
      'subscription_ids': <String>['sub_01'],
    });
    expect(url.toString(), 'https://portal.example.test/o');
  });

  test('a Paddle error becomes a PaddleApiException with its code and detail; '
      'a 404 on getSubscription is null', () async {
    final failing = api(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{
          'error': <String, dynamic>{
            'type': 'request_error',
            'code': 'forbidden',
            'detail': 'no',
          },
        }),
        403,
      ),
    );
    await expectLater(
      failing.createPortalSession(customerId: 'ctm_01'),
      throwsA(
        isA<PaddleApiException>()
            .having((e) => e.code, 'code', 'forbidden')
            .having((e) => e.statusCode, 'status', 403),
      ),
    );

    final missing = api((_) async => http.Response('{}', 404));
    expect(await missing.getSubscription('sub_x'), isNull);
  });

  test(
    'listSubscriptions follows meta.pagination.next while has_more',
    () async {
      var page = 0;
      final client = api((_) async {
        page++;

        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <Map<String, dynamic>>[subscriptionEntity()],
            'meta': <String, dynamic>{
              'pagination': <String, dynamic>{
                'has_more': page < 2,
                'next':
                    'https://sandbox-api.paddle.com/subscriptions?after=sub_01',
              },
            },
          }),
          200,
        );
      });

      final all = await client.listSubscriptions();

      expect(all, hasLength(2));
      expect(requests.last.url.queryParameters['after'], 'sub_01');
    },
  );

  test('PaddleProviderSubscriptions reads a listed subscription as a '
      'correction dated by updated_at, with its scheduled change', () async {
    final entity = subscriptionEntity(
      scheduledChange: <String, dynamic>{
        'action': 'cancel',
        'effective_at': '2026-11-01T12:00:00Z',
      },
    );
    final client = api(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{
          'data': <Map<String, dynamic>>[entity],
          'meta': <String, dynamic>{
            'pagination': <String, dynamic>{'has_more': false},
          },
        }),
        200,
      ),
    );
    final provider = PaddleProviderSubscriptions(
      paddle: client,
      plans: const PaddlePlans(<String, String>{'pro': 'pri_pro'}),
    );

    final state = (await provider.list()).single;

    expect(state.plan, 'pro');
    expect(state.eventAt, DateTime.utc(2026, 10, 1, 12));
    expect(state.scheduledChange?.action, ScheduledAction.cancel);
  });
}
