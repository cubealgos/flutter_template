import 'package:api/src/action_context.dart';
import 'package:api/src/api_router.dart';
import 'package:api/src/function_response.dart';
import 'package:api/src/scheduled_job.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:test/test.dart';

import 'support/recording_action.dart';

Future<FunctionResponse> _handle(
  ApiRouter router,
  Object? body, {
  String? caller = 'user1',
}) => router.handle(
  rawBody: body,
  callerUserId: caller,
  client: Client(),
  environment: const <String, String>{},
);

const _fiveMinutes = Duration(minutes: 5);
const _hour = Duration(hours: 1);
const _threeTicks = 3;

void main() {
  test('dispatches to the named action with the caller and the body minus '
      'the action key', () async {
    final action = RecordingAction();
    final router = ApiRouter(
      actions: <RecordingAction>[action],
      jobs: const [],
    );

    final response = await _handle(router, <String, dynamic>{
      'action': 'echo',
      'x': 1,
    });

    expect(response.statusCode, okStatusCode);
    expect(action.runs.single.callerUserId, 'user1');
    expect(action.runs.single.body, <String, dynamic>{'x': 1});
  });

  test('the caller comes from the header, never the body', () async {
    final action = RecordingAction();
    final router = ApiRouter(
      actions: <RecordingAction>[action],
      jobs: const [],
    );

    await _handle(router, <String, dynamic>{
      'action': 'echo',
      'callerUserId': 'attacker',
      'userId': 'attacker',
    });

    expect(action.runs.single.callerUserId, 'user1');
  });

  test(
    '401 before run when the action needs a user and there is none',
    () async {
      final action = RecordingAction();
      final router = ApiRouter(
        actions: <RecordingAction>[action],
        jobs: const [],
      );

      for (final caller in <String?>[null, '']) {
        final response = await _handle(router, <String, dynamic>{
          'action': 'echo',
        }, caller: caller);
        expect(response.statusCode, unauthenticatedStatusCode);
      }
      expect(action.runs, isEmpty);
    },
  );

  test('an action that does not need a user runs without one', () async {
    final action = RecordingAction(requiresUser: false);
    final router = ApiRouter(
      actions: <RecordingAction>[action],
      jobs: const [],
    );

    final response = await _handle(router, <String, dynamic>{
      'action': 'echo',
    }, caller: null);

    expect(response.statusCode, okStatusCode);
    expect(action.runs.single.callerUserId, isNull);
  });

  test('404 for an unknown action', () async {
    final router = ApiRouter(
      actions: <RecordingAction>[RecordingAction()],
      jobs: const [],
    );

    final response = await _handle(router, <String, dynamic>{'action': 'nope'});

    expect(response.statusCode, unknownActionStatusCode);
  });

  test('400 for a body that is not an object with a string action', () async {
    final router = ApiRouter(
      actions: <RecordingAction>[RecordingAction()],
      jobs: const [],
    );

    for (final body in <Object?>[
      null,
      'echo',
      <Object>[],
      <String, dynamic>{},
      <String, dynamic>{'action': 3},
    ]) {
      expect(
        (await _handle(router, body)).statusCode,
        invalidRequestStatusCode,
      );
    }
  });

  test('an action that throws is a generic 500 and is logged', () async {
    final logs = <String>[];
    final router = ApiRouter(
      actions: <RecordingAction>[RecordingAction(error: Exception('secret'))],
      jobs: const [],
      log: logs.add,
    );

    final response = await _handle(router, <String, dynamic>{'action': 'echo'});

    expect(response.statusCode, internalErrorStatusCode);
    expect(response.body, <String, dynamic>{'error': 'Echo failed.'});
    expect(logs.single, contains('secret'));
  });

  test('rejects two actions with the same name', () {
    expect(
      () => ApiRouter(
        actions: <RecordingAction>[RecordingAction(), RecordingAction()],
        jobs: const [],
      ),
      throwsArgumentError,
    );
  });

  _tickTests();
}

// A test double for the one interface this file exercises.
// ignore: solid_lints/prefer_match_file_name
class _Job implements ScheduledJob {
  _Job(this.name, this.interval, {this.fails = false});

  @override
  final String name;

  @override
  final Duration interval;

  final bool fails;

  final List<int> slots = <int>[];

  @override
  Set<String> get scopes => const <String>{};

  @override
  Future<void> run(ActionContext context, {required int slot}) async {
    slots.add(slot);
    if (fails) throw Exception('boom');
  }
}

Future<FunctionResponse> tick(ApiRouter router, DateTime now) => router.tick(
  now: now,
  client: Client(),
  environment: const <String, String>{},
);

void _tickTests() {
  test('a tick with no registered jobs is a no-op', () async {
    final response = await tick(
      ApiRouter(actions: const [], jobs: const []),
      DateTime.utc(2026),
    );

    expect(response.statusCode, okStatusCode);
    expect(response.body, <String, dynamic>{
      'ran': <String>[],
      'failed': <String>[],
    });
  });

  test(
    'a tick runs only the jobs whose slot boundary fell in the tick',
    () async {
      final everyFive = _Job('five', _fiveMinutes);
      final hourly = _Job('hourly', _hour);
      final router = ApiRouter(
        actions: const [],
        jobs: <ScheduledJob>[everyFive, hourly],
      );

      await tick(router, DateTime.utc(2026, 1, 1, 10, 5, 3));
      await tick(router, DateTime.utc(2026, 1, 1, 10, 10, 3));
      await tick(router, DateTime.utc(2026, 1, 1, 11, 0, 3));

      expect(everyFive.slots.length, _threeTicks);
      expect(hourly.slots, hasLength(1), reason: 'only the 11:00 tick');
    },
  );

  _tickFailureTests();
}

void _tickFailureTests() {
  test('a failing job is reported and does not stop the others', () async {
    final bad = _Job('bad', _fiveMinutes, fails: true);
    final good = _Job('good', _fiveMinutes);
    final logs = <String>[];
    final router = ApiRouter(
      actions: const [],
      jobs: <ScheduledJob>[bad, good],
      log: logs.add,
    );

    final response = await tick(router, DateTime.utc(2026, 1, 1, 10, 5, 3));

    expect(response.body, <String, dynamic>{
      'ran': <String>['good'],
      'failed': <String>['bad'],
    });
    expect(logs.single, contains('bad'));
  });

  test('two deliveries of one tick hand the job the same slot', () async {
    final job = _Job('five', _fiveMinutes);
    final router = ApiRouter(actions: const [], jobs: <ScheduledJob>[job]);

    await tick(router, DateTime.utc(2026, 1, 1, 10, 5, 3));
    await tick(router, DateTime.utc(2026, 1, 1, 10, 5, 40));

    expect(job.slots.toSet().length, 1);
  });

  test('the caller address and the log sink reach the action', () async {
    final action = RecordingAction();
    final logs = <String>[];
    final router = ApiRouter(
      actions: <RecordingAction>[action],
      jobs: const [],
      log: logs.add,
    );

    await router.handle(
      rawBody: <String, dynamic>{'action': 'echo'},
      callerUserId: 'user1',
      client: Client(),
      environment: const <String, String>{},
      callerAddress: '203.0.113.9',
    );

    expect(action.runs.single.callerAddress, '203.0.113.9');
    action.runs.single.log?.call('hello');
    expect(logs, ['hello']);
  });
}
