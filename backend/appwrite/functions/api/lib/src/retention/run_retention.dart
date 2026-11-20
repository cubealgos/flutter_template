import 'package:api/src/action_context.dart';
import 'package:api/src/retention/retention_failed_exception.dart';
import 'package:api/src/retention/retention_report.dart';
import 'package:api/src/retention/retention_rule.dart';

/// Runs [rules] for one scheduled run: the shared body of every retention
/// job (`HousekeepingJob`, `TeamHistoryRetentionJob`).
///
/// 1. Resolves every rule's period first; a set but invalid one throws
///    [FormatException] before anything runs. A rule with no period is
///    skipped, silently: no expiry is configured.
/// 2. Applies each remaining rule in isolation, timing it with [clock]; a
///    rule that throws is reported and the others still run.
/// 3. Logs one line per rule through `ActionContext.log`.
/// 4. If any rule failed, throws [RetentionFailedException] last.
///
/// Returns the reports of the rules that ran.
Future<List<RetentionReport>> runRetention(
  ActionContext context,
  List<RetentionRule> rules, {
  DateTime Function()? clock,
}) async {
  final now = clock ?? DateTime.now;
  final periods = <RetentionRule, Duration>{
    for (final rule in rules) rule: ?rule.periodFrom(context.environment),
  };
  final reports = <RetentionReport>[];
  for (final entry in periods.entries) {
    final started = now().toUtc();
    RetentionReport report;
    try {
      final affected = await entry.key.apply(
        context,
        now: started,
        period: entry.value,
      );
      report = RetentionReport(
        rule: entry.key.name,
        affected: affected,
        duration: now().toUtc().difference(started),
      );
    } on Exception catch (e) {
      report = RetentionReport(
        rule: entry.key.name,
        affected: 0,
        duration: now().toUtc().difference(started),
        error: e,
      );
    }
    context.log?.call(report.line);
    reports.add(report);
  }
  if (reports.any((r) => r.failed)) throw RetentionFailedException(reports);

  return reports;
}
