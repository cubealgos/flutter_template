/// What one retention rule did in one run: the line that is logged.
class RetentionReport {
  /// Creates a report.
  const RetentionReport({
    required this.rule,
    required this.affected,
    required this.duration,
    this.error,
  });

  /// The rule's name.
  final String rule;

  /// Rows deleted or redacted (0 when it failed).
  final int affected;

  /// How long the rule ran.
  final Duration duration;

  /// The error it failed with, if any.
  final Object? error;

  /// Whether the rule failed.
  bool get failed => error != null;

  /// The log line: rule, rows, duration in ms and the error if any.
  String get line =>
      'retention $rule: $affected rows in ${duration.inMilliseconds} ms'
      '${failed ? ', error: $error' : ''}';
}
