// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it - see `backend/appwrite/README.md`). Tagged `integration`
// so it's excluded from `melos run test`'s default run. Run this file alone:
// `cd backend/appwrite/adapters && fvm flutter test --tags integration
// --run-skipped test/integration/appwrite_mail_integration_test.dart`
// and never together with the other suites that deploy `api`.
//
// Email, end to end against the real `api` Function. **Most of it
// needs no SMTP**: the suite sets `MAIL_TRANSPORT=dry` on the Function, which
// records a delivery and sends nothing, and proves
//   - a retried `send_example_mail` writes one `mail_deliveries` row and
//     answers `replayed: true` the second time;
//   - the `mail_unsubscribe` action, with no sign-in needed, only checks a
//     link without `confirm`, records the suppression with it, is idempotent,
//     and suppresses the next non-transactional send;
//   - a tampered, wrong-secret or expired token is refused with 400 and
//     writes no suppression row.
// One test sends a real mail and **skips itself unless** the `.env.local`
// carries `MAIL_SMTP_HOST`, `MAIL_FROM` and `MAIL_TEST_RECIPIENT` (an address
// the person running it can read). The last test executes `GET /unsubscribe`
// (path and query, as a browser on the Function's domain would) and expects
// the HTML pages, with no domain and no extra scope.
//
// **Side effect on the dev project:** the suite replaces the `api` variable
// `MAIL_LINK_SECRET` with a known test value (a secret variable cannot be read
// back, so it cannot be restored) and, when it is done, deletes it and
// re-provisions, which generates a fresh one. Unsubscribe links in mails sent
// before the run stop working. It also sets/removes `MAIL_TRANSPORT`,
// `MAIL_UNSUBSCRIBE_BASE_URL` and (if absent) `RATE_LIMIT_SECRET`.
// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name
@Timeout(Duration(minutes: 8))
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
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:dart_appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:mailing/mailing.dart';

import 'support/deploy_api.dart';
import 'support/path_provider_channel.dart';

const String _testSecret = 'integration-test-link-secret';
const String _baseUrl = 'https://example.test/unsubscribe';

// `setUpAll` populates them before any test runs; there is no earlier point
// to initialize them without `late`.
// ignore: solid_lints/avoid_late_keyword
late BackendEnv _env;
// Same reasoning as `_env`.
// ignore: solid_lints/avoid_late_keyword
late server.Client _adminClient;

final UnsubscribeLinks _links = UnsubscribeLinks(
  secret: _testSecret,
  endpoint: Uri.parse(_baseUrl),
);

/// One signed-in test user with its own client.
// A test fixture named for what it is, not for the file.
class _Person {
  _Person(this.client, this.userId, this.api);

  final Client client;
  final String userId;
  final ApiClient api;
}

void main() {
  final createdUserIds = <String>[];

  Future<_Person> person(String name, {String? email}) async {
    final address =
        email ?? '$name-${DateTime.now().microsecondsSinceEpoch}@example.com';
    final users = server.Users(_adminClient);
    final user = await users.create(userId: server.ID.unique(), email: address);
    createdUserIds.add(user.$id);
    // `send_example_mail` refuses an unverified address.
    await users.updateEmailVerification(
      userId: user.$id,
      emailVerification: true,
    );
    final token = await users.createToken(userId: user.$id);
    final client = Client()
        .setEndpoint(_env.endpoint)
        .setProject(_env.projectId);
    await AppwriteAuthService(client).verifyEmailCode(
      EmailCodeRequest(userId: user.$id, email: address),
      token.secret,
    );

    return _Person(client, user.$id, ApiClient(Functions(client)));
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    initPathProviderChannel('backend_appwrite_mail_integration_');
    HttpOverrides.global = null;
    _env = BackendEnv.load();
    _adminClient = buildClient(_env);
    final provisioner = Provisioner(
      admin: DartAppwriteAdmin(_adminClient),
      schema: templateSchema,
      mail: MailSettings.fromValues(_env.mail),
    );
    await provisioner.run();
    await _setVariable('MAIL_LINK_SECRET', _testSecret, secret: true);
    await _setVariable('MAIL_UNSUBSCRIBE_BASE_URL', _baseUrl);
    await _setVariable('MAIL_TRANSPORT', 'dry');
    await _setVariableIfAbsent('RATE_LIMIT_SECRET', 'integration-rate-secret');
    await deployApi(_adminClient);
  });

  tearDownAll(() async {
    await _deleteVariable('MAIL_TRANSPORT');
    await _deleteVariable('MAIL_LINK_SECRET');
    await Provisioner(
      admin: DartAppwriteAdmin(_adminClient),
      schema: templateSchema,
      mail: MailSettings.fromValues(_env.mail),
    ).run();
    final tables = server.TablesDB(_adminClient);
    for (final id in createdUserIds) {
      await _ignoringAppwrite(() async {
        await tables.deleteRows(
          databaseId: templateSchema.databaseId,
          tableId: 'mail_deliveries',
          queries: <String>[
            server.Query.equal('userId', <String>[id]),
          ],
        );
        await tables.deleteRows(
          databaseId: templateSchema.databaseId,
          tableId: 'mail_suppressions',
          queries: <String>[
            server.Query.equal('userId', <String>[id]),
          ],
        );
      });
      await _ignoringAppwrite(
        () => server.Users(_adminClient).delete(userId: id),
      );
    }
  });

  test('a retried send writes one delivery row and answers replayed', () async {
    final user = await person('retry');

    final first = await _send(user, 'req-1');
    final second = await _send(user, 'req-1');
    final other = await _send(user, 'req-2');

    expect(first['replayed'], isFalse);
    expect(first['status'], 'accepted');
    expect(
      first['detail'],
      contains('dry run'),
      reason: 'MAIL_TRANSPORT=dry is deployed, so nothing is really sent',
    );
    expect(second['replayed'], isTrue);
    expect(other['replayed'], isFalse);
    expect(await _rows('mail_deliveries', user.userId), hasLength(2));
  }, tags: 'integration');

  test('the one-click link unsubscribes without a session, only on confirm, '
      'once, and suppresses the next send', () async {
    final user = await person('unsub');
    final anonymous = _anonymous();
    final token = _links.tokenFor(
      userId: user.userId,
      subscription: digestSubscription,
      locale: MailLocale.en,
    );

    final preview = await _unsubscribe(anonymous, token, confirm: false);
    expect(preview['state'], 'confirm');
    expect(await _rows('mail_suppressions', user.userId), isEmpty);

    final done = await _unsubscribe(anonymous, token, confirm: true);
    expect(done['state'], 'unsubscribed');
    expect(done['alreadyUnsubscribed'], isFalse);
    final again = await _unsubscribe(anonymous, token, confirm: true);
    expect(again['alreadyUnsubscribed'], isTrue);
    expect(await _rows('mail_suppressions', user.userId), hasLength(1));

    final blocked = await _send(user, 'after-unsub');
    expect(blocked['status'], 'suppressed');
  }, tags: 'integration');

  test('a tampered, wrong-secret or expired token is refused and writes '
      'nothing', () async {
    final victim = await person('victim');
    final anonymous = _anonymous();
    final good = _links.tokenFor(
      userId: 'someone-else',
      subscription: digestSubscription,
      locale: MailLocale.en,
    );
    final forVictim = _links.tokenFor(
      userId: victim.userId,
      subscription: digestSubscription,
      locale: MailLocale.en,
    );
    final tampered = '${forVictim.split('.').first}.${good.split('.').last}';
    final wrongSecret =
        UnsubscribeLinks(
          secret: 'not-the-secret',
          endpoint: Uri.parse(_baseUrl),
        ).tokenFor(
          userId: victim.userId,
          subscription: digestSubscription,
          locale: MailLocale.en,
        );
    final expired =
        UnsubscribeLinks(
          secret: _testSecret,
          endpoint: Uri.parse(_baseUrl),
          clock: () => DateTime.now().subtract(const Duration(days: 365)),
        ).tokenFor(
          userId: victim.userId,
          subscription: digestSubscription,
          locale: MailLocale.en,
        );

    for (final token in [tampered, wrongSecret, expired, 'garbage']) {
      await expectLater(
        _unsubscribe(anonymous, token, confirm: true),
        throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 400)),
        reason: token,
      );
    }
    expect(await _rows('mail_suppressions', victim.userId), isEmpty);
  }, tags: 'integration');

  test('with SMTP configured a real mail is accepted by the server', () async {
    // Guarded inside the body, not with `skip:`, because `--run-skipped`
    // (which this suite is run with) overrides `skip:`.
    final recipient = _env.mail['MAIL_TEST_RECIPIENT'];
    if (MailSettings.fromValues(_env.mail) == null ||
        recipient == null ||
        recipient.isEmpty) {
      markTestSkipped(
        'needs MAIL_SMTP_HOST, MAIL_FROM and MAIL_TEST_RECIPIENT in '
        'backend/appwrite/tool/.env.local',
      );

      return;
    }
    await _setVariable('MAIL_TRANSPORT', 'auto');
    await deployApi(_adminClient);
    final user = await person('smtp', email: recipient);

    final result = await _send(user, 'smtp-1');

    expect(result['status'], 'accepted');
    expect(result['replayed'], isFalse);
  }, tags: 'integration');

  test('GET /unsubscribe through an execution returns the HTML pages and '
      'unsubscribes nobody', () async {
    final user = await person('route');
    final garbage = await _getUnsubscribe('garbage');

    expect(garbage.responseStatusCode, 400);
    expect(_header(garbage, 'content-type'), startsWith('text/html'));
    expect(garbage.responseBody, startsWith('<!doctype html>'));
    expect(_header(garbage, 'cache-control'), 'no-store');

    final token = _links.tokenFor(
      userId: user.userId,
      subscription: digestSubscription,
      locale: MailLocale.de,
    );
    final confirm = await _getUnsubscribe(token);

    expect(confirm.responseStatusCode, 200);
    expect(_header(confirm, 'content-type'), startsWith('text/html'));
    expect(confirm.responseBody, startsWith('<!doctype html>'));
    expect(confirm.responseBody, contains('<form method="post"'));
    expect(confirm.responseBody, contains('lang="de"'));
    expect(
      await _rows('mail_suppressions', user.userId),
      isEmpty,
      reason: 'a GET only shows the confirmation',
    );
  }, tags: 'integration');
}

/// Executes `GET /unsubscribe?t=[token]` on the `api` Function from a client
/// with no session, as a recipient's click would arrive (`api` is executable
/// by anyone); this proves `main.dart` maps the path and query and answers
/// HTML without needing a domain or any key scope.
Future<client_models.Execution> _getUnsubscribe(String token) =>
    Functions(Client().setEndpoint(_env.endpoint).setProject(_env.projectId))
        .createExecution(
          functionId: 'api',
          path: '/unsubscribe?t=$token',
          method: client_enums.ExecutionMethod.gET,
          xasync: false,
        );

String? _header(client_models.Execution execution, String name) {
  for (final header in execution.responseHeaders) {
    if (header.name.toLowerCase() == name) return header.value;
  }

  return null;
}

/// A client with no session at all: the unsubscribe link needs none.
ApiClient _anonymous() => ApiClient(
  Functions(Client().setEndpoint(_env.endpoint).setProject(_env.projectId)),
);

Future<Map<String, dynamic>> _send(_Person user, String requestId) async =>
    jsonDecode(
      await user.api.call(
        'send_example_mail',
        fields: <String, dynamic>{'requestId': requestId},
      ),
    ) as Map<String, dynamic>;

Future<Map<String, dynamic>> _unsubscribe(
  ApiClient api,
  String token, {
  required bool confirm,
}) async => jsonDecode(
  await api.call(
    'mail_unsubscribe',
    fields: <String, dynamic>{'token': token, 'confirm': confirm},
  ),
) as Map<String, dynamic>;

Future<List<models.Row>> _rows(String table, String userId) async =>
    (await server.TablesDB(_adminClient).listRows(
      databaseId: templateSchema.databaseId,
      tableId: table,
      queries: <String>[
        server.Query.equal('userId', <String>[userId]),
      ],
    )).rows;

Future<void> _deleteVariable(String key) async {
  final functions = server.Functions(_adminClient);
  final existing = await functions.listVariables(functionId: 'api');
  for (final v in existing.variables.where((v) => v.key == key)) {
    await functions.deleteVariable(functionId: 'api', variableId: v.$id);
  }
}

Future<void> _setVariable(
  String key,
  String value, {
  bool secret = false,
}) async {
  await _deleteVariable(key);
  await server.Functions(_adminClient).createVariable(
    functionId: 'api',
    variableId: server.ID.unique(),
    key: key,
    value: value,
    secret: secret,
  );
}

Future<void> _setVariableIfAbsent(String key, String value) async {
  final existing = await server.Functions(_adminClient)
      .listVariables(functionId: 'api');
  if (existing.variables.any((v) => v.key == key)) return;
  await _setVariable(key, value, secret: true);
}

Future<void> _ignoringAppwrite(Future<void> Function() action) async {
  try {
    await action();
  } on server.AppwriteException {
    // Already gone - the happy path.
  }
}
