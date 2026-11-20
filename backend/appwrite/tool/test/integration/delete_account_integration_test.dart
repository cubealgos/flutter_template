// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it — see
// `backend/appwrite/README.md`). Tagged `integration` so it's excluded from `melos
// run test`'s default `dart test` invocation and only runs via `melos run
// test:integration`.
//
// Provisions the schema, deploys the `api` Function for real, creates a user
// (with an owned `profiles` row), executes the `delete_account` action as
// that user via a
// real session, and asserts the user and their row are actually gone.
//
// `@Timeout` raised from `dart test`'s 30s default: this
// directory now has more than one integration test file that deploys a
// Function to the same Cloud project, and `dart test` runs test files
// concurrently by default - two builds competing for the executor's build
// workers can genuinely take longer than 30s, live-reproduced adding
// `review_demo_sign_in`'s own deployment alongside this one (both now deploy
// the one `api` Function).
@Timeout(Duration(minutes: 3))
@Tags(['integration'])
library;

import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/deploy/archiver.dart';
import 'package:appwrite_tool/src/deploy/bundle_stager.dart';
import 'package:appwrite_tool/src/deploy/deployer.dart';
import 'package:appwrite_tool/src/deploy/pubspec_lock.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as appwrite;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_user.dart';

void main() {
  test('provisions, deploys, and deletes a real user end-to-end', () async {
    final env = BackendEnv.load();
    final client = buildClient(env);

    await _provision(client);
    final deployResult = await _deploy(client);
    expect(
      deployResult.succeeded,
      isTrue,
      reason: 'Build did not succeed: ${deployResult.buildLogs}',
    );

    final testUser = await TestUser.create(env, client);
    addTearDown(() => testUser.deleteIfStillPresent(client));
    await testUser.createOwnedProfileRow(client);

    final executionResponse = await testUser.executeDeleteAccount(env);
    expect(
      executionResponse['userDeleted'],
      isTrue,
      reason: 'delete_account response: $executionResponse',
    );

    await _assertUserAndRowAreGone(client, testUser.userId);
  }, tags: 'integration');
}

Future<void> _provision(appwrite.Client client) async {
  final report = await Provisioner(
    admin: DartAppwriteAdmin(client),
    schema: templateSchema,
  ).run();
  // Either state is fine here - what matters is the schema is now present,
  // not whether this particular run happened to create it.
  expect(report, isNotNull);
}

Future<DeploymentResult> _deploy(appwrite.Client client) async {
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

Future<void> _assertUserAndRowAreGone(
  appwrite.Client client,
  String userId,
) async {
  final users = appwrite.Users(client);
  await expectLater(
    () => users.get(userId: userId),
    throwsA(isA<appwrite.AppwriteException>()),
  );

  final tablesDb = appwrite.TablesDB(client);
  final remainingRows = await tablesDb.listRows(
    databaseId: templateSchema.databaseId,
    tableId: 'profiles',
    queries: <String>[appwrite.Query.equal('userId', userId)],
  );
  expect(remainingRows.total, 0);
}
