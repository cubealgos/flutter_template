// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/actions/jobs/handle_jobs_request.dart';
import 'package:api/src/function_response.dart';
import 'package:jobs/jobs.dart';
import 'package:test/test.dart';

const _worker = 'worker-user';

Future<FunctionResponse> _call(
  FakeJobQueue queue,
  Map<String, dynamic> body, {
  String? caller = _worker,
  Set<String> workers = const {_worker},
}) => handleJobsRequest(
  callerUserId: caller,
  workerUserIds: workers,
  body: body,
  queue: queue,
);

Map<String, dynamic> _result(FunctionResponse response) =>
    Map<String, dynamic>.from(response.body['result'] as Map);

String _code(FunctionResponse response) =>
    (response.body['error'] as Map)['code'] as String;

void main() {
  group('authorisation', () {
    test('only an allow-listed worker identity may call', () async {
      final queue = FakeJobQueue();
      final body = <String, dynamic>{'op': 'status', 'jobId': 'x'};

      for (final response in [
        await _call(queue, body, caller: 'some-end-user'),
        await _call(queue, body, caller: null),
        await _call(queue, body, workers: const {}),
      ]) {
        expect(response.statusCode, 403);
        expect(_code(response), 'forbidden');
      }
    });

    test(
      'the allow-list is a comma separated variable; unset means nobody',
      () {
        expect(workerUsersFrom({jobsWorkerUsersEnvKey: ' a, b ,,c'}), {
          'a',
          'b',
          'c',
        });
        expect(workerUsersFrom(const {}), isEmpty);
        expect(workerUsersFrom({jobsWorkerUsersEnvKey: ''}), isEmpty);
      },
    );
  });

  test(
    'a job goes enqueue, claim, heartbeat, complete over the wire',
    () async {
      final queue = FakeJobQueue();
      final enqueued = await _call(queue, {
        'op': 'enqueue',
        'type': 'scan',
        'payload': {'host': 'example.com'},
        'priority': 'high',
      });
      final claimed = await _call(queue, {
        'op': 'claim',
        'workerId': 'w1',
        'leaseSeconds': 60,
        'types': ['scan'],
      });
      final lease = _result(claimed);
      final beat = await _call(queue, {
        'op': 'heartbeat',
        'lease': lease,
        'leaseSeconds': 60,
      });
      final done = await _call(queue, {
        'op': 'complete',
        'lease': _result(beat),
        'result': {'ok': true},
      });
      final status = await _call(queue, {
        'op': 'status',
        'jobId': _result(enqueued)['id'],
      });

      expect(JobWire.decodeLease(lease).job.payload, {'host': 'example.com'});
      expect(done.statusCode, 200);
      expect(status.body['result'], 'succeeded');
    },
  );

  test('an empty queue answers a null result', () async {
    final response = await _call(FakeJobQueue(), {
      'op': 'claim',
      'workerId': 'w',
      'leaseSeconds': 10,
    });

    expect(response.statusCode, 200);
    expect(response.body['result'], isNull);
  });

  test("a stale worker's write is answered 409 lease_lost", () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a'));
    final stale = (await queue.claim(
      workerId: 'w1',
      leaseFor: const Duration(minutes: 1),
    ))!;
    queue.advance(const Duration(minutes: 5));
    await queue.claim(workerId: 'w2', leaseFor: const Duration(minutes: 1));

    final response = await _call(queue, {
      'op': 'complete',
      'lease': JobWire.encodeLease(stale),
    });

    expect(response.statusCode, 409);
    expect(_code(response), 'lease_lost');
  });

  test('malformed requests are 400, never a 500', () async {
    final queue = FakeJobQueue();
    final bodies = <Map<String, dynamic>>[
      {},
      {'op': 'nope'},
      {'op': 'enqueue'},
      {'op': 'enqueue', 'type': 'a', 'priority': 'urgent'},
      {'op': 'enqueue', 'type': 'a', 'maxAttempts': 'many'},
      {'op': 'enqueue', 'type': 'a', 'availableAt': 'soon'},
      {'op': 'claim', 'workerId': 'w'},
      {'op': 'claim', 'workerId': 'w', 'leaseSeconds': 0},
      {'op': 'claim', 'workerId': 'w', 'leaseSeconds': 100000},
      {'op': 'claim', 'workerId': 'w', 'leaseSeconds': 5, 'types': 'scan'},
      {'op': 'complete'},
      {
        'op': 'complete',
        'lease': {'job': 1},
      },
      {'op': 'status'},
    ];

    for (final body in bodies) {
      final response = await _call(queue, body);

      expect(response.statusCode, 400, reason: '$body');
      expect(_code(response), 'invalid', reason: '$body');
    }
  });
}
