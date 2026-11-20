import 'package:api/src/action_context.dart';
import 'package:api/src/mail/mail_environment.dart';
import 'package:api/src/retention/delete_older_than_rule.dart';
import 'package:api/src/retention/retention_rule.dart';
import 'package:api/src/retention/run_retention.dart';
import 'package:api/src/scheduled_job.dart';

/// The Function variable overriding how long `job_slots` rows are kept, in
/// whole days.
const String jobSlotsRetentionEnvKey = 'JOB_SLOTS_RETENTION_DAYS';

/// How long slot rows are kept by default: long enough to debug a missed run.
const Duration defaultJobSlotsRetention = Duration(days: 30);

/// How long `mail_deliveries` rows are kept by default.
const Duration defaultMailDeliveryRetention = Duration(days: 90);

/// The template's example cron job: hourly, it deletes the rows
/// no one will ever read again - expired `rate_limits` hits (the limiter's
/// keys go no later than their window plus this job's hour) and old
/// `job_slots` claims.
///
/// It is registered wrapped in `OncePerSlotJob` (see `registry.dart`), which
/// is how a clone makes any job safe against a cron that fires twice, and
/// it is a plain list of `RetentionRule`s run by `runRetention`, which logs
/// each rule's rows and duration and reports a failure. A clone adds rules
/// for its own tables (`DeleteOlderThanRule(table:, column:, envKey:)`), or
/// writes a separate job.
class HousekeepingJob implements ScheduledJob {
  /// Creates the job; [rules] is replaceable for tests.
  const HousekeepingJob({this.rules = defaultRules});

  /// What the template cleans: expired rate-limit hits (right at their window
  /// end) and old job slots.
  static const List<RetentionRule> defaultRules = <RetentionRule>[
    DeleteOlderThanRule(
      table: 'rate_limits',
      column: 'expiresAt',
      defaultPeriod: Duration.zero,
    ),
    DeleteOlderThanRule(
      table: 'job_slots',
      column: 'claimedAt',
      envKey: jobSlotsRetentionEnvKey,
      defaultPeriod: defaultJobSlotsRetention,
    ),
    // Delivery records: kept as long as a retried send could
    // still arrive; after that a send with the same key would mail again.
    DeleteOlderThanRule(
      table: 'mail_deliveries',
      column: 'createdAt',
      envKey: mailDeliveryRetentionEnvKey,
      defaultPeriod: defaultMailDeliveryRetention,
    ),
  ];

  /// The rules a run applies.
  final List<RetentionRule> rules;

  @override
  String get name => 'housekeeping';

  @override
  Duration get interval => const Duration(hours: 1);

  @override
  Set<String> get scopes => const <String>{
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
  };

  @override
  Future<void> run(ActionContext context, {required int slot}) async {
    await runRetention(context, rules);
  }
}
