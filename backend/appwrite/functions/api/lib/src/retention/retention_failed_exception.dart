import 'package:api/src/retention/retention_report.dart';

/// Thrown by `runRetention` after every rule ran, when at least one failed,
/// so the router reports the job as failed (the other rules still did their
/// work and were logged).
class RetentionFailedException implements Exception {
  /// Creates the exception over every [reports] of the run.
  const RetentionFailedException(this.reports);

  /// Every rule's report, failed or not.
  final List<RetentionReport> reports;

  @override
  String toString() =>
      'RetentionFailedException: ${[for (final r in reports)
        if (r.failed) r.line].join('; ')}';
}
