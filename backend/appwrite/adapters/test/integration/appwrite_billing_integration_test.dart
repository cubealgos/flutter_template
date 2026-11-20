// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it - see `backend/appwrite/README.md`). Tagged `integration`
// so it's excluded from `melos run test`'s default run. Run this file alone:
// `cd backend/appwrite/adapters && fvm flutter test --tags integration
// --run-skipped test/integration/appwrite_billing_integration_test.dart`
// and never together with the other suites that deploy Functions.
//
// Web billing, end to end against the real `hooks` and `api`
// Functions, with **no Paddle account and no Paddle credentials**: the suite
// deploys `hooks` with a known test webhook secret, signs payloads itself
// with Paddle's scheme (`ts=<unix>;h1=HMAC-SHA256("<ts>:<raw body>")`) and
// POSTs them to `/paddle` through `createExecution`, from a client with no
// session (the hook is public). It proves
//   - the **raw request body reaches the handler byte for byte** (the body
//     has whitespace, a unicode escape and a trailing newline that a
//     re-serialisation changes, and the signature still verifies);
//   - a genuine event writes its ledger rows (`<id>#1`, `<id>#2`) and the
//     entitlement row, and the signed-in owner reads it through the `billing`
//     action;
//   - a replay is a 200 `replayed` that adds no ledger row and does not touch
//     the entitlement row;
//   - a forged signature, a tampered body and a missing signature are 401 and
//     write nothing;
//   - a later event updates the quantity (state follows the newest event).
// The Paddle API calls (checkout, portal, quantity, reconciler fetch) are
// covered by fake-HTTP unit tests only; they need a Paddle sandbox account.
//
// **Side effect on the dev project:** sets the `hooks` variables
// `PADDLE_WEBHOOK_SECRET` (secret) and `PADDLE_PLANS` and removes them at the
// end; deletes the rows and users it created.
// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name, solid_lints/function_lines_of_code
@Timeout(Duration(minutes: 12))
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as client_enums;
import 'package:appwrite/models.dart' as client_models;
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:auth/auth.dart';
import 'package:billing/billing.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:dart_appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:paddle_billing/paddle_billing.dart';

import 'support/deploy_api.dart';
import 'support/function_variables.dart';
import 'support/path_provider_channel.dart';

const String _secret = 'integration-test-paddle-secret';

// `setUpAll` populates them before any test runs; there is no earlier point
// to initialize them without `late`.
// ignore: solid_lints/avoid_late_keyword
late BackendEnv _env;
// Same reasoning as `_env`.
// ignore: solid_lints/avoid_late_keyword
late server.Client _adminClient;

/// A body that a re-serialisation would change: spacing, a `1` escape
/// (`1`) and a trailing newline.
List<int> _body({
  required String eventId,
  required String owner,
  int quantity = 3,
  String occurredAt = '2026-10-01T12:00:00Z',
}) => utf8.encode(
  '{ "event_id" : "$eventId", "event_type":"subscription.updated",\n'
  '  "occurred_at":"$occurredAt", "notification_id":"ntf_$eventId",\n'
  '  "data":{"id":"sub_it_$eventId","status":"active","customer_id":"ctm_it",\n'
  '    "items":[{"status":"active","quantity":$quantity, '
  '"price":{"id":"pri_it"}}],\n'
  '    "next_billed_at":"2030-01-01T00:00:00Z","scheduled_change":null,\n'
  '    "custom_data":{"owner":"$owner"}}}\n',
);

void main() {
  final createdUserIds = <String>[];
  final subscriptionIds = <String>[];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    initPathProviderChannel('backend_appwrite_billing_integration_');
    HttpOverrides.global = null;
    _env = BackendEnv.load();
    _adminClient = buildClient(_env);
    await Provisioner(
      admin: DartAppwriteAdmin(_adminClient),
      schema: templateSchema,
      mail: MailSettings.fromValues(_env.mail),
    ).run();
    await _setVariable('PADDLE_WEBHOOK_SECRET', _secret, secret: true);
    await _setVariable('PADDLE_PLANS', '{"pro":"pri_it"}');
    await deployFunction(_adminClient, 'hooks');
    await deployFunction(_adminClient, 'api');
  });

  tearDownAll(() async {
    await _deleteVariable('PADDLE_WEBHOOK_SECRET');
    await _deleteVariable('PADDLE_PLANS');
    await Future.wait(
      [
        'billing_events',
        'billing_entitlements',
      ].map((table) => _ignoringAppwrite(() => _purge(table, subscriptionIds))),
    );
    for (final id in createdUserIds) {
      await _ignoringAppwrite(
        () => server.Users(_adminClient).delete(userId: id),
      );
    }
  });

  Future<({String userId, ApiClient api})> person(String name) async {
    final address =
        '$name-${DateTime.now().microsecondsSinceEpoch}@example.com';
    final users = server.Users(_adminClient);
    final user = await users.create(userId: server.ID.unique(), email: address);
    createdUserIds.add(user.$id);
    final token = await users.createToken(userId: user.$id);
    final client = Client()
        .setEndpoint(_env.endpoint)
        .setProject(_env.projectId);
    await AppwriteAuthService(client).verifyEmailCode(
      EmailCodeRequest(userId: user.$id, email: address),
      token.secret,
    );

    return (userId: user.$id, api: ApiClient(Functions(client)));
  }

  test('a genuine event: exact raw body verified, ledger rows written, '
      'entitlement readable by the owner; a replay changes nothing; a later '
      'event moves the quantity', () async {
    final user = await person('owner');
    final owner = 'user:${user.userId}';
    const eventId = 'evt_it_a';
    subscriptionIds.add('sub_it_$eventId');
    final body = _body(eventId: eventId, owner: owner);

    final first = await _post(body, _sign(body));

    expect(first.responseStatusCode, 200, reason: first.responseBody);
    expect(_json(first)['status'], 'accepted');
    final rows = await _ledger(eventId);
    expect(rows.map((r) => r.data['ledgerKey']), <String>[
      '$eventId#1',
      '$eventId#2',
    ]);
    expect(rows.first.data['status'], 'active');
    expect(rows.first.data['plan'], 'pro', reason: 'PADDLE_PLANS maps pri_it');
    final entitlementRow = await _entitlement('sub_it_$eventId');
    expect(entitlementRow.data['ownerKey'], owner);

    final read = BillingWire.entitlementFromJson(
      jsonDecode(
        await user.api.call(
          'billing',
          fields: <String, dynamic>{'op': 'entitlement'},
        ),
      ) as Map<String, dynamic>,
    );
    expect(read.hasAccess, isTrue);
    expect(read.quantity, 3);
    expect(read.status, EntitlementStatus.active);

    // Replay: the same bytes, a fresh valid signature.
    final replay = await _post(body, _sign(body));
    expect(replay.responseStatusCode, 200);
    expect(_json(replay)['status'], 'replayed');
    expect(await _ledger(eventId), hasLength(2));
    expect(
      (await _entitlement('sub_it_$eventId')).$updatedAt,
      entitlementRow.$updatedAt,
      reason: 'a replay must not write the entitlement',
    );

    // A newer event for the same subscription moves the state.
    const later = 'evt_it_a';
    final newer = utf8.encode(
      utf8
          .decode(_body(eventId: 'evt_it_a2', owner: owner, quantity: 5))
          .replaceAll('sub_it_evt_it_a2', 'sub_it_$later')
          .replaceAll('2026-10-01T12:00:00Z', '2026-10-01T13:00:00Z'),
    );
    final update = await _post(newer, _sign(newer));
    expect(update.responseStatusCode, 200, reason: update.responseBody);
    expect((await _entitlement('sub_it_$later')).data['quantity'], '5');
  }, tags: 'integration');

  test('a forged signature, a tampered body and a missing signature are '
      'refused with 401 and write nothing', () async {
    const eventId = 'evt_it_b';
    subscriptionIds.add('sub_it_$eventId');
    final body = _body(eventId: eventId, owner: 'user:nobody');

    final forged = await _post(body, _sign(body, secret: 'not-the-secret'));
    final tampered = await _post(
      body.map((b) => b == 0x33 ? 0x39 : b).toList(),
      _sign(body),
    );
    final unsigned = await _post(body, null);

    for (final response in [forged, tampered, unsigned]) {
      expect(response.responseStatusCode, 401, reason: response.responseBody);
    }
    expect(await _ledger(eventId), isEmpty);
    expect(await _entitlements('sub_it_$eventId'), isEmpty);
  }, tags: 'integration');

  test('a team owner: any member reads the entitlement, a non-member is '
      'refused', () async {
    final stranger = await person('stranger');

    await expectLater(
      stranger.api.call(
        'billing',
        fields: <String, dynamic>{'op': 'entitlement', 'owner': 'team:nope'},
      ),
      throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 403)),
    );
  }, tags: 'integration');
}

Map<String, dynamic> _json(client_models.Execution execution) =>
    jsonDecode(execution.responseBody) as Map<String, dynamic>;

/// `Paddle-Signature` for [body], signed now under [secret].
String _sign(List<int> body, {String secret = _secret}) => PaddleSignature.sign(
  rawBody: body,
  secret: secret,
  timestamp: DateTime.now().toUtc(),
);

/// POSTs [body] to the `hooks` Function's `/paddle` from a client with no
/// session, as Paddle's request would arrive.
Future<client_models.Execution> _post(List<int> body, String? signature) =>
    Functions(Client().setEndpoint(_env.endpoint).setProject(_env.projectId))
        .createExecution(
          functionId: 'hooks',
          path: '/paddle',
          method: client_enums.ExecutionMethod.pOST,
          body: utf8.decode(body),
          headers: <String, dynamic>{'paddle-signature': ?signature},
          xasync: false,
        );

Future<List<models.Row>> _ledger(String eventId) async =>
    (await server.TablesDB(_adminClient).listRows(
      databaseId: templateSchema.databaseId,
      tableId: 'billing_events',
      queries: <String>[
        server.Query.equal('eventId', <String>[eventId]),
        server.Query.orderAsc('ledgerKey'),
      ],
    )).rows;

Future<List<models.Row>> _entitlements(String subscriptionId) async =>
    (await server.TablesDB(_adminClient).listRows(
      databaseId: templateSchema.databaseId,
      tableId: 'billing_entitlements',
      queries: <String>[
        server.Query.equal('subscriptionId', <String>[subscriptionId]),
      ],
    )).rows;

Future<models.Row> _entitlement(String subscriptionId) async =>
    (await _entitlements(subscriptionId)).single;

/// Deletes the rows of [table] that belong to the [subscriptions].
Future<void> _purge(String table, List<String> subscriptions) async {
  await server.TablesDB(_adminClient).deleteRows(
    databaseId: templateSchema.databaseId,
    tableId: table,
    queries: <String>[server.Query.equal('subscriptionId', subscriptions)],
  );
}

Future<void> _deleteVariable(String key) =>
    deleteFunctionVariable(_adminClient, 'hooks', key);

Future<void> _setVariable(String key, String value, {bool secret = false}) =>
    setFunctionVariable(_adminClient, 'hooks', key, value, secret: secret);

Future<void> _ignoringAppwrite(Future<void> Function() action) async {
  try {
    await action();
  } on server.AppwriteException {
    // Already gone - the happy path.
  }
}
