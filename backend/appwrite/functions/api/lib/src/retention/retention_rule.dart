import 'package:api/src/action_context.dart';

/// One thing a retention run does to rows older than a period: delete them
/// (`DeleteOlderThanRule`) or redact them (the team history rule).
///
/// A rule must be **idempotent**: applying it twice with the same cutoff
/// changes nothing the second time, so a duplicated or late tick is harmless.
abstract interface class RetentionRule {
  /// A stable name for logs, normally the table.
  String get name;

  /// The retention period in this [environment], or null for "keep forever,
  /// skip this rule". Throws [FormatException] for a set but invalid value,
  /// so a typo fails the job visibly instead of silently never expiring
  /// anything.
  Duration? periodFrom(Map<String, String> environment);

  /// Applies the rule to rows older than `now - period` and returns how many
  /// rows it changed.
  Future<int> apply(
    ActionContext context, {
    required DateTime now,
    required Duration period,
  });
}

/// Reads [key] from [environment] as a positive whole number of days.
///
/// Null when the variable is unset or empty (no expiry); throws
/// [FormatException] for anything else that is not a positive integer.
Duration? retentionDaysFrom(Map<String, String> environment, String key) {
  final raw = environment[key]?.trim();
  if (raw == null || raw.isEmpty) return null;
  final days = int.tryParse(raw);
  if (days == null || days <= 0) {
    throw FormatException('$key must be a positive number of days', raw);
  }

  return Duration(days: days);
}
