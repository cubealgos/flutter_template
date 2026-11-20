// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it — see `backend/appwrite/README.md`). Tagged `integration`
// so it's excluded from `melos run test`'s default run; run via `melos run
// test:integration:backend_appwrite`.
//
// Exercises the real adapters end to end: an admin-created user signed in
// through a real (admin-issued, not emailed — see below) email-code
// secret, document CRUD (`AppwriteDocumentRepository`), file
// upload/download/delete (`AppwriteStorageService`), the "never reveals an
// existing account" contract against a real duplicate-email response, and
// `deleteAccount` actually removing the user. Guest mode (anonymous
// sessions) was removed: every test that used to shortcut
// through `signInAnonymously` now signs in an admin-created user the same
// way `backend/appwrite/tool/test/integration/test_user.dart` does — `Users.create` with
// no password (the `email-password` auth method
// project-wide) plus `Users.createToken`, exchanged for a real session via
// `AppwriteAuthService.verifyEmailCode` — see `_signInAdminCreatedUser`
// below. OAuth and passkey sign-in cannot run headless (a platform browser
// view / native prompt) — those are unit tested against
// `FakeAccountGateway` instead (see `test/appwrite_auth_service_test.dart`).
@Timeout(Duration(minutes: 3))
@Tags(['integration'])
library;

import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:appwrite_tool/src/table_access.dart';
import 'package:auth/auth.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:data/data.dart';
import 'package:flutter/services.dart';
// `flutter_test`, not `package:test` (unlike this package's other test
// files): only this file constructs a real `appwrite` `Client`, and its
// constructor needs a platform-channel binding to exist at all (see
// `_initPathProviderChannel`'s dartdoc). `flutter_test` re-exports every
// `package:test` member this file uses (`test`, `group`, `expect`, …) on
// top of that.
import 'package:flutter_test/flutter_test.dart';

import 'support/deploy_api.dart';

// `setUpAll` populates both before any test runs; there is no earlier
// point to initialize them without `late` (a nullable field would need a
// `!` at every use instead, trading one solid_lints rule for another).
// ignore: solid_lints/avoid_late_keyword
late BackendEnv _env;
// Same reasoning as `_env` above.
// ignore: solid_lints/avoid_late_keyword
late server.Client _adminClient;

// Populated by the second `setUpAll` below — same reasoning as
// `_env`/`_adminClient` above.
// ignore: solid_lints/avoid_late_keyword
late String _reviewDemoTestUserId;

/// The review code this suite's `review_demo_sign_in` deployment is
/// configured with — an arbitrary literal, not a real secret (this is a
/// throwaway deployment torn down with every test run).
const String _reviewDemoTestCode = 'integration-test-review-code-33';

void main() {
  setUpAll(() async {
    // `appwrite`'s `Client` constructor (`ClientIO`) unconditionally
    // resolves a cookie-storage directory via `path_provider`, which
    // needs a live platform-channel binding - absent under a plain
    // `flutter test` run (no widget is ever pumped), it throws "Binding
    // has not yet been initialized" the moment the first `Client()` is
    // constructed (found by hand). `TestWidgetsFlutterBinding` supplies
    // the binding; `path_provider`'s own channel still has no real
    // platform implementation to answer it, so it's mocked directly.
    TestWidgetsFlutterBinding.ensureInitialized();
    _initPathProviderChannel();

    // `TestWidgetsFlutterBinding` also installs an `HttpOverrides` that
    // fakes every `HttpClient` request as a 400 with no body, specifically
    // to keep an ordinary widget test from ever making a real network
    // call by accident (found by hand: both `dart_appwrite`'s admin calls
    // and `appwrite`'s own session calls failed identically with
    // "Unexpected empty response with status 400" until this was unset).
    // This suite's whole point is a real network call against a real
    // Appwrite project, so that override is removed.
    HttpOverrides.global = null;

    // `BackendEnv.load()` finds the shared `backend/appwrite/tool/.env.local` that every
    // worktree of this clone resolves to whatever the current
    // directory — this package's melos script runs `flutter test` from
    // `backend/appwrite/adapters/`.
    _env = BackendEnv.load();
    _adminClient = buildClient(_env);
    await Provisioner(
      admin: DartAppwriteAdmin(_adminClient),
      schema: templateSchema,
    ).run();
    await _deployDeleteAccount(_adminClient);
  });

  test('admin-created user -> document create/read/delete', () async {
    final client = _buildUserClient();
    final authService = AppwriteAuthService(client);
    final session = await _signInAdminCreatedUser(authService);
    addTearDown(() => _deleteUserIfPresent(session.userId));

    final repo = AppwriteDocumentRepository(
      client,
      databaseId: templateSchema.databaseId,
      tableId: 'profiles',
    );
    final created = await repo.create(<String, dynamic>{
      'displayName': 'Integration',
    });
    expect(created.data['displayName'], 'Integration');
    expect(created.data['userId'], session.userId);

    final read = await repo.read(created.id);
    expect(read.data['displayName'], 'Integration');

    await repo.delete(created.id);
    await expectLater(
      () => repo.read(created.id),
      throwsA(isA<DataNotFoundError>()),
    );
  }, tags: 'integration');

  test('admin-created user -> file upload/download/delete', () async {
    final client = _buildUserClient();
    final authService = AppwriteAuthService(client);
    final session = await _signInAdminCreatedUser(authService);
    addTearDown(() => _deleteUserIfPresent(session.userId));

    final storage = AppwriteStorageService(client, bucketId: 'avatars');
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final uploaded = await storage.upload(fileName: 'avatar.png', bytes: bytes);
    final downloaded = await storage.download(uploaded.id);
    expect(downloaded, bytes);

    await storage.delete(uploaded.id);
    await expectLater(
      () => storage.download(uploaded.id),
      throwsA(isA<DataNotFoundError>()),
    );
  }, tags: 'integration');

  test('requestEmailCode reuses the existing account', () async {
    final email = _uniqueEmail('existing');
    // Admin-created, no password (`Provisioner` disables the
    // project's `email-password` auth method entirely, so the public
    // `Account.create(..., password: ...)` this used before is refused -
    // see `Provisioner.unusedAuthMethods`'s dartdoc). Still a real,
    // pre-existing account for `requestEmailCode` to find by email.
    final existingUser = await server.Users(_adminClient)
        .create(userId: server.ID.unique(), email: email);
    addTearDown(() => _deleteUserIfPresent(existingUser.$id));

    final authService = AppwriteAuthService(_buildUserClient());
    final result = await authService.requestEmailCode(email);

    // No distinguishing error was thrown for the already-registered
    // address (the interface-level "never reveals existence" contract) -
    // and, verified live: real Appwrite doesn't just avoid erroring, it
    // transparently issues the token for the *existing* account. A fresh
    // `ID.unique()` was passed in (see AppwriteAuthService.requestEmailCode)
    // but the returned userId is the pre-existing user's real ID, not a
    // new one - see AppwriteAuthService's "Email-code existence finding"
    // dartdoc.
    expect(result.email, email);
    expect(result.userId, existingUser.$id);
  }, tags: 'integration');

  test('verifyEmailCode signs in with an admin-issued token secret', () async {
    final email = _uniqueEmail('otp');
    // Admin-created, no password - see the previous test's identical note.
    final user = await server.Users(_adminClient)
        .create(userId: server.ID.unique(), email: email);
    addTearDown(() => _deleteUserIfPresent(user.$id));

    // Account.createEmailToken (the real client flow) never returns
    // `secret` outside an API-key-authenticated response - it's
    // genuinely emailed, and a test can't read the inbox. The admin
    // Users API creates the same shape of token with `secret`
    // populated, since that call is authenticated with an API key -
    // confirmed against `Token.secret`'s own dartdoc ("This will
    // return an empty string unless the response is returned using
    // an API key").
    final adminToken = await server.Users(_adminClient)
        .createToken(userId: user.$id);

    final authService = AppwriteAuthService(_buildUserClient());
    final session = await authService.verifyEmailCode(
      EmailCodeRequest(userId: user.$id, email: email),
      adminToken.secret,
    );

    expect(session.userId, user.$id);
  }, tags: 'integration');

  test('deleteAccount actually removes the user', () async {
    final client = _buildUserClient();
    final authService = AppwriteAuthService(client);
    final session = await _signInAdminCreatedUser(authService);

    await authService.deleteAccount();

    await expectLater(
      () => server.Users(_adminClient).get(userId: session.userId),
      throwsA(isA<server.AppwriteException>()),
    );
  }, tags: 'integration');

  test('deleteAccount is refused for a team owner, naming the team, and '
      'deletes nothing', () async {
    final client = _buildUserClient();
    final authService = AppwriteAuthService(client);
    final session = await _signInAdminCreatedUser(authService);
    addTearDown(() => _deleteUserIfPresent(session.userId));
    // `team_admin` (which `createTeam` calls) matches on a verified email.
    await server.Users(
      _adminClient,
    ).updateEmailVerification(userId: session.userId, emailVerification: true);
    final team = await AppwriteTeamService(client).createTeam('Owned team');
    // Best effort, like the teams suite's cleanup: the harness key may lack
    // `teams.write`, and a leftover dev-project team is harmless.
    addTearDown(() async {
      try {
        await server.Teams(_adminClient).delete(teamId: team.id);
      } on server.AppwriteException {
        // Ignored on purpose; see above.
      }
    });

    await expectLater(
      authService.deleteAccount,
      throwsA(
        isA<AuthOwnsTeamsError>().having(
          (e) => e.teamNames,
          'teamNames',
          <String>['Owned team'],
        ),
      ),
    );

    // Refused server-side, before anything was deleted: the user and the
    // session are still there.
    expect(authService.currentSession, isNotNull);
    final stillThere = await server.Users(_adminClient)
        .get(userId: session.userId);
    expect(stillThere.$id, session.userId);
  }, tags: 'integration');

  test(
    'AppwriteUserPreferences: read-merge-write over the replace-only '
    'Account.updatePrefs — updating one key leaves the other alone',
    () async {
      final client = _buildUserClient();
      final authService = AppwriteAuthService(client);
      final session = await _signInAdminCreatedUser(authService);
      addTearDown(() => _deleteUserIfPresent(session.userId));

      final preferences = AppwriteUserPreferences(client);
      await preferences.update(<String, dynamic>{
        'consentAccepted': true,
        'onboardingDismissed': false,
      });
      final afterFirstWrite = await preferences.getAll();
      expect(afterFirstWrite['consentAccepted'], isTrue);
      expect(afterFirstWrite['onboardingDismissed'], isFalse);

      // A real `Account.updatePrefs` call replaces the whole preferences
      // object server-side — this only proves anything if
      // `AppwriteUserPreferences.update` itself reads-merges-writes on top
      // of that, not if it happened to pass every key through every time.
      await preferences.update(<String, dynamic>{'consentAccepted': false});
      final afterSecondWrite = await preferences.getAll();
      expect(afterSecondWrite['consentAccepted'], isFalse);
      expect(afterSecondWrite['onboardingDismissed'], isFalse);
    },
    tags: 'integration',
  );

  test(
    'AppwriteVersionPolicy: the app_config row is readable from an '
    'unauthenticated client (publicRead), and blocks/allows correctly',
    () async {
      const rowId = 'integration-version-check';
      await server.TablesDB(_adminClient).createRow(
        databaseId: templateSchema.databaseId,
        tableId: 'app_config',
        rowId: rowId,
        data: <String, dynamic>{
          'minSupportedVersion': '2.0.0',
          'updateUrlIOS': 'https://example.com/update/ios',
          'updateUrlAndroid': 'https://example.com/update/android',
          'updateUrlWeb': 'https://example.com/update/web',
          'message': 'please update',
        },
      );
      addTearDown(() => _deleteAppConfigRowIfPresent(rowId));

      // No API key, and never signed in — genuinely unauthenticated,
      // proving `TableSchema.publicRead`'s `Role.any()` grant actually
      // works, not just that an admin/session client can read it.
      final unauthenticatedClient = _buildUserClient();
      final policy = AppwriteVersionPolicy(unauthenticatedClient, rowId: rowId);

      final belowMinimum = await policy.check('1.0.0');
      expect(belowMinimum.blocked, isTrue);
      // Not asserting *which* per-platform URL: `flutter test` runs this
      // suite on the host with no real device, and `defaultTargetPlatform`
      // (what `AppwriteVersionPolicy._updateUrl` switches on) resolves to
      // `TargetPlatform.android` in that harness regardless of the actual
      // host OS — found running this test. The platform-selection switch
      // itself is plain, already-covered logic; what this test proves is
      // that the row (seeded above, with all three URLs set) really came
      // back from the publicly readable table.
      expect(belowMinimum.updateUrl, isNotNull);
      expect(
        belowMinimum.updateUrl.toString(),
        startsWith('https://example.com/update/'),
      );

      final aboveMinimum = await policy.check('3.0.0');
      expect(aboveMinimum.blocked, isFalse);
    },
    tags: 'integration',
  );

  test('AppwriteVersionPolicy fails open when the row is absent', () async {
    final policy = AppwriteVersionPolicy(
      _buildUserClient(),
      rowId: 'integration-row-that-does-not-exist',
    );

    final result = await policy.check('0.0.1');

    expect(result.blocked, isFalse);
  }, tags: 'integration');

  test(
    'AppwriteAuthService.restoreSession resumes a session created by '
    'another instance on the same Client, and returns null after sign-out',
    () async {
      final client = _buildUserClient();
      final firstInstance = AppwriteAuthService(client);
      final session = await _signInAdminCreatedUser(firstInstance);
      addTearDown(() => _deleteUserIfPresent(session.userId));

      // A fresh AppwriteAuthService, same underlying Client — the only
      // thing that could carry the session across is the Client's own
      // (cookie-based) session state, which is exactly what
      // `restoreSession` is meant to pick up.
      final secondInstance = AppwriteAuthService(client);
      final restored = await secondInstance.restoreSession();
      expect(restored?.userId, session.userId);
      expect(secondInstance.currentSession?.userId, session.userId);

      await secondInstance.signOut();

      final thirdInstance = AppwriteAuthService(client);
      final afterSignOut = await thirdInstance.restoreSession();
      expect(afterSignOut, isNull);
    },
    tags: 'integration',
  );

  // A second, independent `setUpAll` — the `test` package runs every
  // registered `setUpAll` in order before any test, so this deploys and
  // seeds the `review_demo_sign_in` action without touching the
  // existing `setUpAll` above at all.
  setUpAll(() async {
    // Already deployed by the first setUpAll: both actions are served by
    // the one `api` Function.
    final demoUser = await server.Users(_adminClient).create(
      userId: server.ID.unique(),
      email: _uniqueEmail('review-demo'),
      name: 'Review Demo Integration',
    );
    _reviewDemoTestUserId = demoUser.$id;
    await _setReviewDemoFunctionVariablesIfMissing(
      _adminClient,
      userId: _reviewDemoTestUserId,
      code: _reviewDemoTestCode,
    );
  });
  tearDownAll(() => _deleteUserIfPresent(_reviewDemoTestUserId));

  test('signInWithReviewCode exchanges the configured code for a session on '
      'the configured demo account', () async {
    final authService = AppwriteAuthService(_buildUserClient());

    final session = await authService.signInWithReviewCode(_reviewDemoTestCode);

    expect(session.userId, _reviewDemoTestUserId);
    expect(authService.currentSession, session);
  }, tags: 'integration');

  test('signInWithReviewCode maps a wrong code to AuthInvalidCodeError, live '
      'against a real deployed Function, and issues no session', () async {
    final authService = AppwriteAuthService(_buildUserClient());

    await expectLater(
      () => authService.signInWithReviewCode('definitely-not-the-code'),
      throwsA(isA<AuthInvalidCodeError>()),
    );
    expect(authService.currentSession, isNull);
  }, tags: 'integration');

  // Table-level read/update/delete grants made every signed-in
  // user able to touch every row. These prove row isolation for real: user
  // B, holding a valid session, cannot get, list, update or delete a row
  // that only user A's permissions name - in `profiles` and in a second
  // signed-in table provisioned the same way.
  test('table-level grants are create-only on a provisioned signed-in '
      'table', () async {
    final table = await server.TablesDB(_adminClient)
        .getTable(databaseId: templateSchema.databaseId, tableId: 'profiles');

    expect(table.$permissions, <String>['create("users")']);
    expect(table.rowSecurity, isTrue);
  }, tags: 'integration');

  test('a second user cannot get, list, update or delete a profiles row '
      'of the first', () async {
    await _expectRowIsolated(tableId: 'profiles', data: _profileData);
  }, tags: 'integration');

  test('a second user cannot get, list, update or delete a row of the first in '
      'another signed-in table', () async {
    const tableId = 'integration_isolation';
    final admin = DartAppwriteAdmin(_adminClient);
    await _deleteTableIfPresent(tableId);
    await admin.createTable(
      databaseId: templateSchema.databaseId,
      tableId: tableId,
      name: 'Integration isolation',
      access: TableAccess.signedIn,
    );
    addTearDown(() => _deleteTableIfPresent(tableId));
    for (final key in <String>['userId', 'note']) {
      await admin.createColumn(
        databaseId: templateSchema.databaseId,
        tableId: tableId,
        column: ColumnSchema(
          key: key,
          type: key == 'userId' ? ColumnType.varchar : ColumnType.text,
        ),
      );
    }

    await _expectRowIsolated(
      tableId: tableId,
      data: <String, dynamic>{'note': 'A only'},
    );
  }, tags: 'integration');
}

/// A client built the way an app actually would — no API key, session
/// auth only (via `Account.createSession`). Cloud serves real HTTPS, so
/// Appwrite's `Secure` session cookie round-trips through the client SDK's
/// cookie jar as it does for an app.
Client _buildUserClient() =>
    Client().setEndpoint(_env.endpoint).setProject(_env.projectId);

/// Mocks the `path_provider` platform channel `appwrite`'s `Client` needs
/// (see `setUpAll`'s dartdoc) — a fresh temp directory per call, so every
/// `Client()` this file constructs gets its own on-disk cookie jar rather
/// than sharing (and leaking session cookies through) one directory.
void _initPathProviderChannel() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'getApplicationDocumentsDirectory') return null;
        final dir = await Directory.systemTemp.createTemp(
          'backend_appwrite_integration_',
        );
        addTearDown(() => _deleteTempDirRobustly(dir));

        return dir.path;
      });
}

/// How many times [_deleteTempDirRobustly] retries a delete that raced a
/// concurrent write into the same directory — seen once locally:
/// `cookie_jar`'s own async persistence write landing a file into the
/// cookie-jar directory between the delete's directory listing and its
/// last removal throws `FileSystemException: Directory not empty`.
const int _tempDirDeleteMaxAttempts = 5;

/// The delay between [_deleteTempDirRobustly]'s retries.
const Duration _tempDirDeleteRetryDelay = Duration(milliseconds: 50);

/// Deletes [dir] recursively, retrying on `FileSystemException` up to
/// [_tempDirDeleteMaxAttempts] times (with [_tempDirDeleteRetryDelay]
/// between attempts) instead of letting one transient race — a
/// concurrent cookie-jar write, not a real cleanup failure — fail the
/// whole test run over this best-effort temp-dir cleanup. Rethrows if
/// every attempt fails, since a delete that keeps failing past the race
/// window is a real problem, not a race.
Future<void> _deleteTempDirRobustly(Directory dir) async {
  for (var attempt = 1; attempt <= _tempDirDeleteMaxAttempts; attempt++) {
    try {
      await dir.delete(recursive: true);

      return;
    } on FileSystemException {
      if (attempt == _tempDirDeleteMaxAttempts) rethrow;
      await Future<void>.delayed(_tempDirDeleteRetryDelay);
    }
  }
}

String _uniqueEmail(String prefix) =>
    '$prefix-${DateTime.now().millisecondsSinceEpoch}@example.com';

/// Signs [authService] in as a fresh, admin-created user — the replacement
/// for the `signInAnonymously()` shortcut guest mode's removal
/// took away, for tests that just need *some* signed-in session rather
/// than to exercise a specific sign-in flow. Admin-created with no
/// password (`email-password` is disabled project-wide by `Provisioner` —
/// see `Provisioner.unusedAuthMethods`'s dartdoc — so the public sign-up
/// endpoint this used before is refused), then signed in for real through
/// [authService]'s own `verifyEmailCode` with an admin-issued token secret
/// — the same admin-created-user + admin-issued-token pattern
/// `backend/appwrite/tool/test/integration/test_user.dart` uses, adapted to go through
/// the real `AuthService` interface instead of a raw HTTP call.
Future<AuthSession> _signInAdminCreatedUser(
  AppwriteAuthService authService,
) async {
  final email = _uniqueEmail('admin-created');
  final user = await server.Users(_adminClient)
      .create(userId: server.ID.unique(), email: email);
  final token = await server.Users(_adminClient).createToken(userId: user.$id);

  return await authService.verifyEmailCode(
    EmailCodeRequest(userId: user.$id, email: email),
    token.secret,
  );
}

/// Deploys the `api` Function for real, mirroring
/// `backend/appwrite/tool/test/integration/delete_account_integration_test.dart` — this
/// package's own integration suite can't assume that test already ran.
Future<void> _deployDeleteAccount(server.Client adminClient) =>
    deployApi(adminClient);

/// Best-effort cleanup — keeps repeated local runs from accumulating stray
/// accounts if an assertion fails before a test's own deletion happens.
Future<void> _deleteUserIfPresent(String userId) async {
  try {
    await server.Users(_adminClient).delete(userId: userId);
  } on server.AppwriteException {
    // Already gone — the happy path.
  }
}

/// Same reasoning as [_deleteUserIfPresent], for a seeded `app_config` row.
Future<void> _deleteAppConfigRowIfPresent(String rowId) async {
  try {
    await server.TablesDB(_adminClient).deleteRow(
      databaseId: templateSchema.databaseId,
      tableId: 'app_config',
      rowId: rowId,
    );
  } on server.AppwriteException {
    // Already gone — the happy path.
  }
}

/// Sets `review_demo_sign_in`'s `REVIEW_DEMO_USER_ID`/`REVIEW_DEMO_CODE`
/// function variables to [userId]/[code], creating or updating each as
/// needed. Unlike `backend/appwrite/tool/bin/seed_review_demo_account.dart`'s own
/// production "never overwrite a secret" policy, this *always* sets both
/// values: this suite creates a fresh demo user every run (see the second
/// `setUpAll` above), so a stale value left over from an earlier run of
/// this same suite must be overwritten, not preserved, for
/// `_reviewDemoTestUserId` to actually match what the deployed Function
/// will hand out tokens for.
Future<void> _setReviewDemoFunctionVariablesIfMissing(
  server.Client adminClient, {
  required String userId,
  required String code,
}) async {
  final functions = server.Functions(adminClient);
  final existing = await functions.listVariables(functionId: 'api');
  final values = <String, String>{
    'REVIEW_DEMO_USER_ID': userId,
    'REVIEW_DEMO_CODE': code,
  };

  for (final entry in values.entries) {
    final match = existing.variables.where(
      (variable) => variable.key == entry.key,
    );
    if (match.isEmpty) {
      await functions.createVariable(
        functionId: 'api',
        variableId: server.ID.unique(),
        key: entry.key,
        value: entry.value,
      );
    } else {
      await functions.updateVariable(
        functionId: 'api',
        variableId: match.first.$id,
        value: entry.value,
      );
    }
  }
}

const Map<String, dynamic> _profileData = <String, dynamic>{
  'displayName': 'User A',
};

/// The statuses Appwrite answers a row the caller may not touch with:
/// 401 `user_unauthorized`, 403, or 404 when it hides the row entirely.
const List<int> _deniedStatusCodes = <int>[401, 403, 404];

/// Signs in two users, has A create a row in [tableId] through
/// `AppwriteDocumentRepository`, then proves B - with raw `TablesDB` calls,
/// so nothing filters on the owner column - cannot get, list, update or
/// delete it, while A still can.
Future<void> _expectRowIsolated({
  required String tableId,
  required Map<String, dynamic> data,
}) async {
  final ownerClient = _buildUserClient();
  final intruderClient = _buildUserClient();
  final ownerSession = await _signInAdminCreatedUser(
    AppwriteAuthService(ownerClient),
  );
  final intruderSession = await _signInAdminCreatedUser(
    AppwriteAuthService(intruderClient),
  );
  addTearDown(() => _deleteUserIfPresent(ownerSession.userId));
  addTearDown(() => _deleteUserIfPresent(intruderSession.userId));

  final created = await AppwriteDocumentRepository(
    ownerClient,
    databaseId: templateSchema.databaseId,
    tableId: tableId,
  ).create(data);
  final databaseId = templateSchema.databaseId;
  final intruderTables = TablesDB(intruderClient);

  await _expectIntruderDenied(
    intruderTables,
    tableId: tableId,
    rowId: created.id,
    data: data,
  );

  // The row survived B's attempts, untouched, and A still owns it.
  final adminRow = await server.TablesDB(_adminClient)
      .getRow(databaseId: databaseId, tableId: tableId, rowId: created.id);
  expect(adminRow.data['userId'], ownerSession.userId);
  final asOwner = await TablesDB(ownerClient)
      .getRow(databaseId: databaseId, tableId: tableId, rowId: created.id);
  expect(asOwner.$id, created.id);
}

/// Asserts `intruderTables`, a signed-in client not owning row `rowId`, can
/// neither get, list, update nor delete it.
Future<void> _expectIntruderDenied(
  TablesDB intruderTables, {
  required String tableId,
  required String rowId,
  required Map<String, dynamic> data,
}) async {
  final databaseId = templateSchema.databaseId;
  await expectLater(
    () => intruderTables.getRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: rowId,
    ),
    throwsA(_denied),
  );

  // List: no error is required (a list filters), but A's row is absent.
  final listed = await intruderTables.listRows(
    databaseId: databaseId,
    tableId: tableId,
  );
  expect(listed.rows.map((row) => row.$id), isNot(contains(rowId)));

  await expectLater(
    () => intruderTables.updateRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: rowId,
      data: data,
    ),
    throwsA(_denied),
  );
  await expectLater(
    () => intruderTables.deleteRow(
      databaseId: databaseId,
      tableId: tableId,
      rowId: rowId,
    ),
    throwsA(_denied),
  );
}

final Matcher _denied = isA<AppwriteException>().having(
  (e) => e.code,
  'code',
  isIn(_deniedStatusCodes),
);

/// Best-effort cleanup of the throwaway table the second isolation test
/// provisions.
Future<void> _deleteTableIfPresent(String tableId) async {
  try {
    await server.TablesDB(_adminClient)
        .deleteTable(databaseId: templateSchema.databaseId, tableId: tableId);
  } on server.AppwriteException {
    // Absent - the happy path.
  }
}
