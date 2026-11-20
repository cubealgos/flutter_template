// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/housekeeping_job.dart';
import 'package:api/src/registry.dart';
import 'package:api/src/retention/delete_older_than_rule.dart';
import 'package:api/src/schedule/once_per_slot_job.dart';
import 'package:test/test.dart';

import 'support/in_memory_stores.dart';
import 'support/test_context.dart';

void main() {
  test('deletes expired rate-limit hits at once and old job slots after 30 '
      'days', () async {
    final now = DateTime.now().toUtc();
    final store = InMemoryRetentionStore()
      ..tables['rate_limits'] = [
        now.subtract(const Duration(minutes: 1)),
        now.add(const Duration(minutes: 5)),
      ]
      ..tables['job_slots'] = [
        now.subtract(const Duration(days: 31)),
        now.subtract(const Duration(days: 29)),
      ];
    final job = HousekeepingJob(
      rules: [
        for (final rule in HousekeepingJob.defaultRules)
          DeleteOlderThanRule(
            table: (rule as DeleteOlderThanRule).table,
            column: rule.column,
            envKey: rule.envKey,
            defaultPeriod: rule.defaultPeriod,
            storeFor: (_) => store,
          ),
      ],
    );
    final logs = <String>[];

    await job.run(testContext(logs: logs), slot: 1);

    expect(store.tables['rate_limits'], hasLength(1), reason: 'live hit kept');
    expect(store.tables['job_slots'], hasLength(1));
    expect(logs, hasLength(HousekeepingJob.defaultRules.length));
  });

  test('the slot retention is overridable by variable', () {
    final rule = HousekeepingJob.defaultRules.firstWhere(
      (rule) => rule.name == 'job_slots',
    );

    expect(
      rule.periodFrom({jobSlotsRetentionEnvKey: '7'}),
      const Duration(days: 7),
    );
    expect(rule.periodFrom(const {}), defaultJobSlotsRetention);
  });

  test('is registered once-per-slot, hourly, next to the team job', () {
    final registered = scheduledJobs.whereType<OncePerSlotJob>().singleWhere(
      (j) => j.inner is HousekeepingJob,
    );

    expect(registered.inner, isA<HousekeepingJob>());
    expect(registered.interval, const Duration(hours: 1));
    expect(
      scheduledJobs.map((j) => j.name),
      contains('team_history_retention'),
    );
  });
}
