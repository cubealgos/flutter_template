// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it — see `backend/appwrite/README.md`). Tagged `integration`
// so it's excluded from `melos run test`'s default run. Run this file alone:
// `cd backend/appwrite/adapters && fvm flutter test --tags integration
// --run-skipped test/integration/appwrite_server_primitives_integration_test.dart`
// and never together with `appwrite_teams_integration_test.dart`: both deploy
// the `api` Function, and two concurrent deploys collide.
//
// The server primitives, end to end against the real thing:
// provisions the schema, allow-lists a worker user in `JOBS_WORKER_USER_IDS`,
// deploys the `api` router for real and proves that
//   - of several concurrent claimers of one job, exactly one wins (the unique
//     (jobId, attempt) claim row, since TablesDB has no compare-and-set);
//   - a worker whose lease expired and was taken over is rejected on every
//     write, and the job completes with the new attempt's result;
//   - a signed-in user who is not a worker is refused with 403;
//   - `DocumentRepository.update` with a stale `expectedVersion` is refused
//     with `DataConflictError` against a real row's `$updatedAt`.
// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name
@Timeout(Duration(minutes: 6))
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
import 'package:auth/auth.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobs/jobs.dart';

import 'support/deploy_api.dart';
import 'support/path_provider_channel.dart';

const String _workerVariable = 'JOBS_WORKER_USER_IDS';
const Duration _lease = Duration(seconds: 2);

// `setUpAll` populates them before any test runs; there is no earlier point
// to initialize them without `late`.
// ignore: solid_lints/avoid_late_keyword
late BackendEnv _env;
// Same reasoning as `_env`.
// ignore: solid_lints/avoid_late_keyword
late server.Client _adminClient;
// Same reasoning as `_env`.
// ignore: solid_lints/avoid_late_keyword
late _Person _worker;

/// One signed-in test user with its own client.
// A test fixture named for what it is, not for the file.
class _Person {
  _Person(this.client, this.userId);

  final Client client;
  final String userId;
}

void main() {
  final createdUserIds = <String>[];
  final jobTypes = <String>[];

  Future<_Person> person(String name) async {
    final email = '$name-${DateTime.now().microsecondsSinceEpoch}@example.com';
    final users = server.Users(_adminClient);
    final user = await users.create(userId: server.ID.unique(), email: email);
    createdUserIds.add(user.$id);
    final token = await users.createToken(userId: user.$id);
    final client = Client()
        .setEndpoint(_env.endpoint)
        .setProject(_env.projectId);
    await AppwriteAuthService(client).verifyEmailCode(
      EmailCodeRequest(userId: user.$id, email: email),
      token.secret,
    );

    return _Person(client, user.$id);
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    initPathProviderChannel('backend_appwrite_primitives_integration_');
    HttpOverrides.global = null;
    _env = BackendEnv.load();
    _adminClient = buildClient(_env);
    await Provisioner(
      admin: DartAppwriteAdmin(_adminClient),
      schema: templateSchema,
    ).run();
    _worker = await person('worker');
    await _allowListWorker(_worker.userId);
    await deployApi(_adminClient);
  });

  tearDownAll(() async {
    for (final type in jobTypes) {
      await _cleanupJobs(type);
    }
    await _ignoringAppwrite(() async {
      final variables = server.Functions(_adminClient);
      final all = await variables.listVariables(functionId: 'api');
      for (final v in all.variables.where((v) => v.key == _workerVariable)) {
        await variables.deleteVariable(functionId: 'api', variableId: v.$id);
      }
    });
    for (final id in createdUserIds) {
      await _ignoringAppwrite(
        () => server.Users(_adminClient).delete(userId: id),
      );
    }
  });

  String newType() {
    final type = 'it-${DateTime.now().microsecondsSinceEpoch}';
    jobTypes.add(type);

    return type;
  }

  test('of concurrent claimers of one job exactly one wins', () async {
    final queue = AppwriteJobQueue(_worker.client);
    final type = newType();
    await queue.enqueue(NewJob(type: type, payload: <String, dynamic>{'n': 1}));

    final results = await Future.wait([
      for (var i = 0; i < 4; i++)
        queue.claim(
          workerId: 'w$i',
          leaseFor: const Duration(minutes: 1),
          types: {type},
        ),
    ]);

    expect(results.whereType<JobLease>(), hasLength(1));
    final lease = results.whereType<JobLease>().single;
    await queue.complete(lease, result: <String, dynamic>{'ok': true});
    expect(await queue.status(lease.job.id), JobStatus.succeeded);
  }, tags: 'integration');

  test(
    'a worker that lost its lease is rejected; the new attempt completes',
    () async {
      final queue = AppwriteJobQueue(_worker.client);
      final type = newType();
      final job = await queue.enqueue(NewJob(type: type));

      final stale = (await queue.claim(
        workerId: 'crashed',
        leaseFor: _lease,
        types: {type},
      ))!;
      expect(
        await queue.claim(workerId: 'other', leaseFor: _lease, types: {type}),
        isNull,
        reason: 'the lease is still live',
      );
      await Future<void>.delayed(_lease + const Duration(seconds: 1));
      final current = (await queue.claim(
        workerId: 'rescuer',
        leaseFor: const Duration(minutes: 1),
        types: {type},
      ))!;

      expect(current.attempt, stale.attempt + 1);
      await expectLater(
        queue.complete(stale),
        throwsA(isA<JobLeaseLostError>()),
      );
      await expectLater(
        queue.heartbeat(stale, leaseFor: _lease),
        throwsA(isA<JobLeaseLostError>()),
      );
      await expectLater(
        queue.fail(stale, error: 'late'),
        throwsA(isA<JobLeaseLostError>()),
      );
      expect(await queue.status(job.id), JobStatus.running);
      await queue.complete(current);
      expect(await queue.status(job.id), JobStatus.succeeded);
    },
    tags: 'integration',
  );

  test('a signed-in user who is not a worker is refused', () async {
    final stranger = await person('stranger');

    await expectLater(
      AppwriteJobQueue(stranger.client).enqueue(NewJob(type: newType())),
      throwsA(isA<JobPermissionError>()),
    );
  }, tags: 'integration');

  test(
    'update with a stale expectedVersion is refused with DataConflictError',
    () async {
      final owner = await person('editor');
      final repo = AppwriteDocumentRepository(
        owner.client,
        databaseId: templateSchema.databaseId,
        tableId: 'profiles',
      );
      final created = await repo.create(<String, dynamic>{
        'displayName': 'Ada',
      });
      final read = await repo.read(created.id);
      expect(read.version, isNotNull);
      // Appwrite's `$updatedAt` has millisecond resolution; make sure the next
      // write lands in a later millisecond.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final first = await repo.update(created.id, <String, dynamic>{
        'displayName': 'Grace',
      }, expectedVersion: read.version);
      expect(first.version, isNot(read.version));

      await expectLater(
        repo.update(created.id, <String, dynamic>{
          'displayName': 'Hopper',
        }, expectedVersion: read.version),
        throwsA(isA<DataConflictError>()),
      );
      expect((await repo.read(created.id)).data['displayName'], 'Grace');
      final accepted = await repo.update(created.id, <String, dynamic>{
        'displayName': 'Hopper',
      }, expectedVersion: first.version);
      expect(accepted.data['displayName'], 'Hopper');
    },
    tags: 'integration',
  );
}

/// Sets `JOBS_WORKER_USER_IDS` on the `api` Function to [userId], replacing
/// any earlier value. Done before the deploy, so the new execution sees it.
Future<void> _allowListWorker(String userId) async {
  final functions = server.Functions(_adminClient);
  final existing = await functions.listVariables(functionId: 'api');
  for (final v in existing.variables.where((v) => v.key == _workerVariable)) {
    await functions.deleteVariable(functionId: 'api', variableId: v.$id);
  }
  await functions.createVariable(
    functionId: 'api',
    variableId: server.ID.unique(),
    key: _workerVariable,
    value: userId,
  );
}

Future<void> _ignoringAppwrite(Future<void> Function() action) async {
  try {
    await action();
  } on server.AppwriteException {
    // Already gone — the happy path.
  }
}

/// Deletes the jobs of [type] and their claims.
Future<void> _cleanupJobs(String type) async {
  await _ignoringAppwrite(() async {
    final tables = server.TablesDB(_adminClient);
    final jobs = await tables.listRows(
      databaseId: templateSchema.databaseId,
      tableId: 'jobs',
      queries: <String>[
        server.Query.equal('type', <String>[type]),
      ],
    );
    for (final job in jobs.rows) {
      await tables.deleteRows(
        databaseId: templateSchema.databaseId,
        tableId: 'job_claims',
        queries: <String>[
          server.Query.equal('jobId', <String>[job.$id]),
        ],
      );
      await tables.deleteRow(
        databaseId: templateSchema.databaseId,
        tableId: 'jobs',
        rowId: job.$id,
      );
    }
  });
}
