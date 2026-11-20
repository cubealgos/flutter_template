// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/action_context.dart';
import 'package:api/src/retention/delete_older_than_rule.dart';
import 'package:api/src/retention/retention_failed_exception.dart';
import 'package:api/src/retention/retention_rule.dart';
import 'package:api/src/retention/run_retention.dart';
import 'package:test/test.dart';

import '../support/in_memory_stores.dart';
import '../support/test_context.dart';

final _now = DateTime.utc(2026, 6);

class _Rule implements RetentionRule {
  _Rule(this.name, {this.period, this.error, this.affected = 0});

  @override
  final String name;
  final Duration? period;
  final Exception? error;
  final int affected;
  int applied = 0;

  @override
  Duration? periodFrom(Map<String, String> environment) => period;

  @override
  Future<int> apply(
    ActionContext context, {
    required DateTime now,
    required Duration period,
  }) async {
    applied++;
    if (error case final Exception failure) throw failure;

    return affected;
  }
}

void main() {
  test('deletes only rows older than the period, per table, and logs the '
      'rows and duration of each run', () async {
    final store = InMemoryRetentionStore()
      ..tables['a'] = [
        _now.subtract(const Duration(days: 40)),
        _now.subtract(const Duration(days: 2)),
      ]
      ..tables['b'] = [_now.subtract(const Duration(days: 40))];
    final logs = <String>[];
    var tick = 0;
    final reports = await runRetention(
      testContext(environment: const {'A_DAYS': '30'}, logs: logs),
      [
        DeleteOlderThanRule(
          table: 'a',
          column: 'at',
          envKey: 'A_DAYS',
          storeFor: (_) => store,
        ),
        DeleteOlderThanRule(
          table: 'b',
          column: 'at',
          defaultPeriod: const Duration(days: 60),
          storeFor: (_) => store,
        ),
      ],
      clock: () => _now.add(Duration(milliseconds: 5 * tick++)),
    );

    expect(store.tables['a'], hasLength(1));
    expect(store.tables['b'], hasLength(1), reason: 'inside 60 days');
    expect(reports.map((r) => r.affected), [1, 0]);
    expect(logs, [
      'retention a: 1 rows in 5 ms',
      'retention b: 0 rows in 5 ms',
    ]);
  });

  test('is idempotent: a second run deletes nothing more', () async {
    final store = InMemoryRetentionStore()..tables['a'] = [DateTime.utc(2020)];
    final rule = DeleteOlderThanRule(
      table: 'a',
      column: 'at',
      defaultPeriod: const Duration(days: 1),
      storeFor: (_) => store,
    );

    final first = await runRetention(testContext(), [rule]);
    final second = await runRetention(testContext(), [rule]);

    expect(first.single.affected, 1);
    expect(second.single.affected, 0);
  });

  test('a rule with no period is skipped', () async {
    final rule = _Rule('a');

    final reports = await runRetention(testContext(), [rule]);

    expect(rule.applied, 0);
    expect(reports, isEmpty);
  });

  test('a set but invalid period throws before anything runs', () async {
    final other = _Rule('other', period: const Duration(days: 1));
    const bad = DeleteOlderThanRule(table: 'a', column: 'at', envKey: 'A_DAYS');

    for (final value in ['abc', '0', '-3', '1.5']) {
      await expectLater(
        runRetention(testContext(environment: {'A_DAYS': value}), [other, bad]),
        throwsFormatException,
        reason: value,
      );
    }
    expect(other.applied, 0);
  });

  test('a failing rule is reported and logged, the others still run, and the '
      'run fails at the end', () async {
    final failing = _Rule(
      'bad',
      period: const Duration(days: 1),
      error: Exception('boom'),
    );
    final good = _Rule('good', period: const Duration(days: 1), affected: 3);
    final logs = <String>[];

    await expectLater(
      runRetention(testContext(logs: logs), [failing, good]),
      throwsA(
        isA<RetentionFailedException>().having(
          (e) => e.reports.map((r) => r.failed).toList(),
          'failed flags',
          [true, false],
        ),
      ),
    );

    expect(good.applied, 1);
    expect(logs.first, contains('retention bad: 0 rows'));
    expect(logs.first, contains('error: Exception: boom'));
    expect(logs.last, contains('retention good: 3 rows'));
  });
}
