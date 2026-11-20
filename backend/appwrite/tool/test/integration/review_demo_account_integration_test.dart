// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it — see
// `backend/appwrite/README.md`). Tagged `integration` so it's excluded from `melos
// run test`'s default `dart test` invocation and only runs via `melos run
// test:integration`.
//
// Deploys `review_demo_sign_in` for real, seeds a real demo account and
// the Function's variables end to end (`seedReviewDemoAccount` against
// `DartAppwriteReviewDemoAccountGateway`), confirms a second seeding run
// is a true no-op, and confirms the deployed Function actually works when
// called the way an unauthenticated app client would: the right code
// yields a real session token for the demo user and only that user, and a
// wrong code is refused with no token issued — proving the account this
// script seeds is genuinely usable end to end, not just present in the
// `Users`/`Functions` list.
//
// `@Timeout` raised from `dart test`'s 30s default — see
// `delete_account_integration_test.dart`'s identical note; this file is
// the other concurrently running deployment that note refers to.
@Timeout(Duration(minutes: 3))
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/dart_appwrite_review_demo_account_gateway.dart';
import 'package:appwrite_tool/src/deploy/archiver.dart';
import 'package:appwrite_tool/src/deploy/bundle_stager.dart';
import 'package:appwrite_tool/src/deploy/deployer.dart';
import 'package:appwrite_tool/src/deploy/pubspec_lock.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:appwrite_tool/src/review_demo_account.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('deploys api, seeds it end to end, is idempotent, and '
      'the deployed Function really exchanges the right code for a session '
      'on the demo user only', () async {
    final env = BackendEnv.load();
    final client = buildClient(env);
    await Provisioner(
      admin: DartAppwriteAdmin(client),
      schema: templateSchema,
    ).run();
    final deployResult = await _deployReviewDemoSignIn(client);
    expect(
      deployResult.succeeded,
      isTrue,
      reason: 'Build did not succeed: ${deployResult.buildLogs}',
    );
    // This suite reuses the one long-lived Cloud project across runs,
    // so `review_demo_sign_in`'s function variables can already be set
    // from an earlier run of this exact test - clear them first so the
    // "creates a fresh code" assertion below is deterministic rather than
    // depending on whether this happens to be the very first run ever.
    await _resetReviewDemoFunctionVariables(client);

    final gateway = DartAppwriteReviewDemoAccountGateway(client);
    final email =
        'review-demo-integration-'
        '${DateTime.now().millisecondsSinceEpoch}@example.com';

    final firstRun = await seedReviewDemoAccount(
      gateway: gateway,
      email: email,
    );
    addTearDown(() => _deleteUserIfPresent(client, firstRun.userId));
    final generatedCode = firstRun.generatedCode;
    expect(generatedCode, isNotNull);

    final secondRun = await seedReviewDemoAccount(
      gateway: gateway,
      email: email,
    );
    expect(secondRun.userId, firstRun.userId);
    expect(secondRun.generatedCode, isNull);

    await _assertExecutionSucceeds(
      env: env,
      code: generatedCode ?? '',
      expectedUserId: firstRun.userId,
    );
    await _assertExecutionRejected(env: env, code: 'not-the-real-code');

    await _assertBlankVariableFilled(client, gateway, email, firstRun.userId);
  }, tags: 'integration');
}

/// Stages, archives and deploys the `api` Function for real — mirrors
/// `delete_account_integration_test.dart`'s own `_deploy`, deliberately not
/// shared with it: each integration suite in this workspace deploys its
/// own Function independently (`backend/appwrite/adapters`'s own
/// integration suite does the same for `delete_account` - see that
/// package's `_deployDeleteAccount`), so neither file depends on the
/// other's structure holding still.
// ignore: solid_lints/avoid_duplicate_code
Future<DeploymentResult> _deployReviewDemoSignIn(server.Client client) async {
  final repoRoot = findRepoRoot(Directory.current);
  final lockfile = PubspecLock.parse(
    File(p.join(repoRoot.path, 'pubspec.lock')).readAsStringSync(),
  );
  final function = templateSchema.functions.singleWhere((f) => f.id == 'api');

  final stagingDir = BundleStager(
    repoRoot: repoRoot,
    lockfile: lockfile,
  ).stage(function);
  addTearDown(() => stagingDir.deleteSync(recursive: true));

  final archiveFile = File(
    p.join(stagingDir.parent.path, 'api_integration.tar.gz'),
  );
  await createDeploymentArchive(sourceDir: stagingDir, outputFile: archiveFile);
  addTearDown(archiveFile.deleteSync);

  return await Deployer(client)
      .deploy(function: function, archive: archiveFile);
}

/// Calls the deployed Function the way an unauthenticated app client would
/// — no API key, no session, project header only (`execute: ['any']`) —
/// with [code], and asserts it returns a real session token for
/// [expectedUserId].
Future<void> _assertExecutionSucceeds({
  required BackendEnv env,
  required String code,
  required String expectedUserId,
}) async {
  final body = await _executeReviewDemoSignIn(env, code);
  expect(body['userId'], expectedUserId, reason: 'response: $body');
  expect(body['secret'], isNotEmpty, reason: 'response: $body');
}

/// Same call as [_assertExecutionSucceeds], but with a wrong [code] —
/// asserts no token is present in the (error) response.
Future<void> _assertExecutionRejected({
  required BackendEnv env,
  required String code,
}) async {
  final body = await _executeReviewDemoSignIn(env, code);
  expect(body['secret'], isNull, reason: 'response: $body');
  expect(body['error'], isNotNull, reason: 'response: $body');
}

Future<Map<String, dynamic>> _executeReviewDemoSignIn(
  BackendEnv env,
  String code,
) async {
  // A genuinely unauthenticated client - no API key, no session - to
  // actually exercise `execute: ['any']`, not an admin bypass.
  final publicClient = server.Client()
      .setEndpoint(env.endpoint)
      .setProject(env.projectId);
  final execution = await server.Functions(publicClient).createExecution(
    functionId: 'api',
    body: jsonEncode(<String, dynamic>{
      'action': 'review_demo_sign_in',
      'code': code,
    }),
    headers: <String, dynamic>{'content-type': 'application/json'},
    xasync: false,
  );

  return jsonDecode(execution.responseBody) as Map<String, dynamic>;
}

/// Best-effort cleanup — keeps repeated local runs from accumulating stray
/// accounts if an assertion fails before the test's own deletion happens.
Future<void> _deleteUserIfPresent(server.Client client, String userId) async {
  try {
    await server.Users(client).delete(userId: userId);
  } on server.AppwriteException {
    // Already gone — the happy path.
  }
}

/// Deletes `review_demo_sign_in`'s `REVIEW_DEMO_USER_ID`/`REVIEW_DEMO_CODE`
/// function variables if present — see this test's own "creates a fresh
/// code" comment for why.
Future<void> _resetReviewDemoFunctionVariables(server.Client client) async {
  final functions = server.Functions(client);
  final existing = await functions.listVariables(functionId: 'api');
  for (final variable in existing.variables) {
    if (variable.key != 'REVIEW_DEMO_USER_ID' &&
        variable.key != 'REVIEW_DEMO_CODE') {
      continue;
    }
    await functions.deleteVariable(functionId: 'api', variableId: variable.$id);
  }
}

/// A non-secret code variable left blank (the only kind whose
/// value the API reveals - Cloud hides secret ones, so blank is
/// unobservable there) counts as unconfigured and is filled in place.
Future<void> _assertBlankVariableFilled(
  server.Client client,
  DartAppwriteReviewDemoAccountGateway gateway,
  String email,
  String expectedUserId,
) async {
  final functions = server.Functions(client);
  await _resetReviewDemoFunctionVariables(client);
  await functions.createVariable(
    functionId: reviewDemoFunctionId,
    variableId: server.ID.unique(),
    key: reviewDemoCodeVariableKey,
    value: '',
    secret: false,
  );
  final blankRun = await seedReviewDemoAccount(gateway: gateway, email: email);
  expect(blankRun.generatedCode, isNotNull);
  expect(blankRun.userId, expectedUserId);
  // No execution check here: a warm Function runtime keeps the env it
  // started with, so it may still hold the previous code.
  final codeVariables = (await functions.listVariables(
    functionId: reviewDemoFunctionId,
  )).variables.where((v) => v.key == reviewDemoCodeVariableKey);
  expect(codeVariables, hasLength(1), reason: 'updated, not duplicated');
}
