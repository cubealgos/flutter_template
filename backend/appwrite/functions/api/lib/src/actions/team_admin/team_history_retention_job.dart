import 'package:api/src/action_context.dart';
import 'package:api/src/actions/team_admin/appwrite_team_store.dart';
import 'package:api/src/retention/retention_rule.dart';
import 'package:api/src/retention/run_retention.dart';
import 'package:api/src/scheduled_job.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:teams/teams.dart';

/// The Function environment variable holding the retention period, in whole
/// days, of the email snapshots in the team membership history. **Unset (the
/// template's default) means no expiry**: the job does nothing. A clone sets
/// it through `FunctionSchema.variables` of `api` (365 is a common choice).
const String teamHistoryRetentionEnvKey = 'TEAM_HISTORY_EMAIL_RETENTION_DAYS';

/// Builds the engine a job run uses, over [context]'s client.
typedef TeamEngineFactory = TeamEngine Function(ActionContext context);

TeamEngine _appwriteEngine(ActionContext context) => TeamEngine(
  store: AppwriteTeamStore(
    client: context.client,
    databaseId: templateSchema.databaseId,
  ),
);

/// Daily job that replaces the email snapshot of every membership-history
/// event older than the configured retention by `MembershipEvent.formerMember`.
/// It is one `RetentionRule` run through `runRetention`, the
/// shared retention helper, so it logs its rows and duration like
/// every retention job.
///
/// Idempotent per slot (a second run changes nothing), so a duplicated or late
/// cron tick is harmless. A set but invalid period throws, so the router
/// reports the job as failed instead of silently never expiring anything.
class TeamHistoryRetentionJob implements ScheduledJob {
  /// Creates the job; [engineFor] is replaceable for tests.
  const TeamHistoryRetentionJob({this.engineFor = _appwriteEngine});

  /// Builds the engine a run uses.
  final TeamEngineFactory engineFor;

  @override
  String get name => 'team_history_retention';

  @override
  Duration get interval => const Duration(days: 1);

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
    await runRetention(context, <RetentionRule>[
      TeamHistoryEmailRule(engineFor: engineFor),
    ]);
  }
}

/// The retention rule of the membership history: redacts the email snapshots
/// older than the period instead of deleting the rows (the user IDs, event
/// types, roles and times stay; only the readable address goes).
class TeamHistoryEmailRule implements RetentionRule {
  /// Creates the rule; [engineFor] is replaceable for tests.
  const TeamHistoryEmailRule({this.engineFor = _appwriteEngine});

  /// Builds the engine a run uses.
  final TeamEngineFactory engineFor;

  @override
  String get name => 'team_membership_events';

  @override
  Duration? periodFrom(Map<String, String> environment) =>
      retentionDaysFrom(environment, teamHistoryRetentionEnvKey);

  @override
  Future<int> apply(
    ActionContext context, {
    required DateTime now,
    required Duration period,
  }) => engineFor(context).redactEmailsOlderThan(period);
}
