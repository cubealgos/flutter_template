// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:billing/billing.dart';
import 'package:hooks/src/hook_router.dart';
import 'package:hooks/src/paddle_hook.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late Stores stores;
  late PaddleHook hook;
  late HookRouter router;

  setUp(() {
    stores = Stores();
    hook = PaddleHook(clock: () => now, engineFor: (_) => stores.engine());
    router = HookRouter(hooks: [hook]);
  });

  test('a genuine event is recorded in the ledger and updates the '
      'entitlement', () async {
    final response = await router.handle(paddleRequest(eventBody));

    expect(response.statusCode, 200);
    expect(response.body['status'], 'accepted');
    expect(stores.ledger.entries.map((e) => e.key), <String>[
      'evt_01#1',
      'evt_01#2',
    ], reason: 'a subscription event is a state change and a scheduled change');
    final entitlement = await EntitlementReader(
      store: stores.entitlements,
      clock: () => now,
    ).forOwner(const BillingOwner.team('t1'));
    expect(entitlement.hasAccess, isTrue);
    expect(entitlement.quantity, 3);
    expect(entitlement.plan, 'pro');
  });

  test('a replayed event answers 200 and changes nothing', () async {
    await router.handle(paddleRequest(eventBody));
    final rows = stores.ledger.entries.length;
    final writes = stores.entitlements.writes;

    final replay = await router.handle(paddleRequest(eventBody));

    expect(replay.statusCode, 200);
    expect(replay.body['status'], 'replayed');
    expect(stores.ledger.entries, hasLength(rows));
    expect(stores.entitlements.writes, writes);
  });

  test('a forged signature is rejected with 401 and writes nothing', () async {
    final logs = <String>[];

    final response = await router.handle(
      paddleRequest(eventBody, secret: 'the-attackers-secret', logs: logs),
    );

    expect(response.statusCode, 401);
    expect(response.body['error'], 'invalid_signature');
    expect(stores.ledger.entries, isEmpty);
    expect(stores.entitlements.writes, 0);
    expect(logs.single, contains('mismatch'));
  });

  test('a body altered after signing is rejected', () async {
    final signed = paddleRequest(eventBody);
    final altered = paddleRequest(
      eventBody.map((b) => b == 0x33 ? 0x39 : b).toList(),
      signature: signed.headers['paddle-signature'],
    );

    final response = await router.handle(altered);

    expect(response.statusCode, 401);
    expect(stores.ledger.entries, isEmpty);
  });

  test('a missing, malformed or stale signature is rejected', () async {
    for (final signature in ['', 'garbage', 'ts=1;h1=00']) {
      final response = await router.handle(
        paddleRequest(eventBody, signature: signature),
      );
      expect(response.statusCode, 401, reason: signature);
    }
    final stale = await router.handle(
      paddleRequest(
        eventBody,
        signedAt: now.subtract(const Duration(hours: 1)),
      ),
    );
    expect(stale.statusCode, 401);
    expect(stores.ledger.entries, isEmpty);
  });

  test(
    'without a configured secret the hook refuses everything with 500',
    () async {
      final response = await router.handle(
        paddleRequest(eventBody, environment: const <String, String>{}),
      );

      expect(response.statusCode, 500);
      expect(stores.ledger.entries, isEmpty);
    },
  );

  test('a signed body that is not a Paddle event is a 400 and writes '
      'nothing', () async {
    final response = await router.handle(paddleRequest([0x7b, 0x7d]));

    expect(response.statusCode, 400);
    expect(stores.ledger.entries, isEmpty);
  });

  test('a ledger failure is a 500 (Paddle retries) and no entitlement is '
      'written', () async {
    final failing = Stores();
    final broken = HookRouter(
      hooks: [
        PaddleHook(
          clock: () => now,
          engineFor: (_) => BillingEngine(
            ledger: _DownLedger(),
            entitlements: failing.entitlements,
          ),
        ),
      ],
    );

    final response = await broken.handle(paddleRequest(eventBody));

    expect(response.statusCode, 500);
    expect(response.body['error'], 'failed');
    expect(failing.entitlements.writes, 0);
  });

  test('a transaction event is kept in the ledger and changes no '
      'entitlement', () async {
    const body =
        '{"event_id":"evt_tx","event_type":"transaction.completed",'
        '"occurred_at":"2026-10-01T12:00:00Z","notification_id":"n",'
        '"data":{"id":"txn_1"}}';

    final response = await router.handle(paddleRequest(body.codeUnits));

    expect(response.statusCode, 200);
    expect(stores.ledger.entries.single.kind, LedgerKind.recorded);
    expect(stores.entitlements.writes, 0);
  });
}

class _DownLedger extends InMemoryBillingLedger {
  @override
  Future<bool> append(LedgerEntry entry) async =>
      throw Exception('database down');
}
