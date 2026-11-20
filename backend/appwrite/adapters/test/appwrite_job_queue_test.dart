// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:jobs/jobs.dart';
import 'package:test/test.dart';

import 'fakes/appwrite_model_fixtures.dart';

final _job = Job(
  id: 'j1',
  type: 'scan',
  payload: const <String, dynamic>{'host': 'example.com'},
  priority: JobPriority.high,
  maxAttempts: 3,
  availableAt: DateTime.utc(2026),
  createdAt: DateTime.utc(2026),
);

final _lease = JobLease(
  job: _job,
  attempt: 2,
  workerId: 'w',
  leaseExpiresAt: DateTime.utc(2026, 1, 1, 0, 1),
);

void main() {
  test('claim sends the op and decodes the lease', () async {
    Map<String, dynamic>? sent;
    final queue = AppwriteJobQueue.withApi(
      ApiClient.withExecutor(({
        required functionId,
        required body,
        required headers,
      }) async {
        sent = jsonDecode(body) as Map<String, dynamic>;

        return fakeExecution(
          status: 200,
          body: jsonEncode(<String, dynamic>{
            'result': JobWire.encodeLease(_lease),
          }),
        );
      }),
    );

    final lease = await queue.claim(
      workerId: 'w',
      leaseFor: const Duration(minutes: 1),
      types: <String>{'scan'},
    );

    expect(sent, <String, dynamic>{
      'action': 'jobs',
      'op': 'claim',
      'workerId': 'w',
      'leaseSeconds': 60,
      'types': <String>['scan'],
    });
    expect(lease?.attempt, 2);
    expect(lease?.job.payload, <String, dynamic>{'host': 'example.com'});
  });

  test('an empty queue answers a null lease', () async {
    final queue = AppwriteJobQueue.withApi(
      ApiClient.withExecutor(
        ({required functionId, required body, required headers}) async =>
            fakeExecution(status: 200, body: '{"result":null}'),
      ),
    );

    expect(
      await queue.claim(workerId: 'w', leaseFor: const Duration(minutes: 1)),
      isNull,
    );
  });

  test("the action's refusals come back as typed JobErrors", () async {
    AppwriteJobQueue failing(int status, JobError error) =>
        AppwriteJobQueue.withApi(
          ApiClient.withExecutor(
            ({required functionId, required body, required headers}) async =>
                fakeExecution(
                  status: status,
                  body: jsonEncode(JobWire.encodeError(error)),
                ),
          ),
        );

    await expectLater(
      failing(409, const JobLeaseLostError('stale')).complete(_lease),
      throwsA(isA<JobLeaseLostError>()),
    );
    await expectLater(
      failing(
        403,
        const JobPermissionError('no'),
      ).enqueue(const NewJob(type: 'a')),
      throwsA(isA<JobPermissionError>()),
    );
  });

  test("a failure that is not the action's propagates untouched", () async {
    final queue = AppwriteJobQueue.withApi(
      ApiClient.withExecutor(
        ({required functionId, required body, required headers}) async =>
            throw AppwriteException('offline', 0),
      ),
    );

    await expectLater(queue.status('j1'), throwsA(isA<AppwriteException>()));
  });
}
