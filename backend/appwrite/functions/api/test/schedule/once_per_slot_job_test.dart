// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/action_context.dart';
import 'package:api/src/schedule/once_per_slot_job.dart';
import 'package:api/src/scheduled_job.dart';
import 'package:test/test.dart';

import '../support/in_memory_stores.dart';
import '../support/test_context.dart';

class _Counting implements ScheduledJob {
  _Counting({this.failFirst = false});

  final bool failFirst;
  final List<int> slots = <int>[];

  @override
  String get name => 'counting';

  @override
  Duration get interval => const Duration(days: 7);

  @override
  Set<String> get scopes => const <String>{'users.read'};

  @override
  Future<void> run(ActionContext context, {required int slot}) async {
    slots.add(slot);
    if (failFirst && slots.length == 1) throw Exception('boom');
  }
}

void main() {
  test('a double slot: the same slot delivered twice runs once', () async {
    final inner = _Counting();
    final slots = InMemorySlotStore();
    final job = OncePerSlotJob(inner, slotsFor: (_) => slots);
    final logs = <String>[];

    await job.run(testContext(logs: logs), slot: 7);
    await job.run(testContext(logs: logs), slot: 7);

    expect(inner.slots, [7]);
    expect(logs.single, contains('slot 7 already ran'));
  });

  test('two concurrent fires of one slot run it once', () async {
    final inner = _Counting();
    final slots = InMemorySlotStore();
    final job = OncePerSlotJob(inner, slotsFor: (_) => slots);

    await Future.wait([
      job.run(testContext(), slot: 3),
      job.run(testContext(), slot: 3),
      job.run(testContext(), slot: 3),
    ]);

    expect(inner.slots, [3]);
  });

  test('the next slot runs again', () async {
    final inner = _Counting();
    final job = OncePerSlotJob(inner, slotsFor: (_) => InMemorySlotStore());
    final slots = InMemorySlotStore();
    final shared = OncePerSlotJob(inner, slotsFor: (_) => slots);

    await shared.run(testContext(), slot: 1);
    await shared.run(testContext(), slot: 2);

    expect(inner.slots, [1, 2]);
    expect(job.name, 'counting');
  });

  test('a failed run releases its slot so a re-delivered tick retries, and '
      'the failure propagates', () async {
    final inner = _Counting(failFirst: true);
    final slots = InMemorySlotStore();
    final job = OncePerSlotJob(inner, slotsFor: (_) => slots);

    await expectLater(
      job.run(testContext(), slot: 5),
      throwsA(isA<Exception>()),
    );
    await job.run(testContext(), slot: 5);

    expect(inner.slots, [5, 5]);
  });

  test('delegates name and interval, and adds the slot table scopes', () {
    final job = OncePerSlotJob(_Counting());

    expect(job.interval, const Duration(days: 7));
    expect(job.scopes, containsAll(['users.read', 'documents.write']));
  });
}
