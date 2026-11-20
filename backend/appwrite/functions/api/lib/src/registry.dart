import 'package:api/src/actions/billing/billing_action.dart';
import 'package:api/src/actions/billing/billing_reconciler_job.dart';
import 'package:api/src/actions/delete_account/delete_account_action.dart';
import 'package:api/src/actions/jobs/jobs_action.dart';
import 'package:api/src/actions/mail_unsubscribe/mail_unsubscribe_action.dart';
import 'package:api/src/actions/review_demo_sign_in/review_demo_sign_in_action.dart';
import 'package:api/src/actions/send_example_mail/send_example_mail_action.dart';
import 'package:api/src/actions/team_admin/team_admin_action.dart';
import 'package:api/src/actions/team_admin/team_history_retention_job.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/housekeeping_job.dart';
import 'package:api/src/schedule/once_per_slot_job.dart';
import 'package:api/src/scheduled_job.dart';

/// Every action the `api` Function serves. **To add one, append it here**
/// (and declare its scopes on the action itself) - nothing else changes;
/// see "Adding an action" in `backend/appwrite/README.md`.
const List<ApiAction> actions = <ApiAction>[
  BillingAction(),
  DeleteAccountAction(),
  JobsAction(),
  MailUnsubscribeAction(),
  ReviewDemoSignInAction(),
  SendExampleMailAction(),
  TeamAdminAction(),
];

/// Every scheduled job the cron tick dispatches. A clone appends its own.
/// `TeamHistoryRetentionJob` does nothing until
/// `TEAM_HISTORY_EMAIL_RETENTION_DAYS` is set (no expiry by default).
/// `BillingReconcilerJob` compares Paddle with the entitlements
/// and does nothing until `PADDLE_API_KEY` is set.
/// `HousekeepingJob` is the example of a once-per-slot job: wrapped in
/// `OncePerSlotJob`, so a cron tick delivered twice runs it once.
const List<ScheduledJob> scheduledJobs = <ScheduledJob>[
  TeamHistoryRetentionJob(),
  OncePerSlotJob(HousekeepingJob()),
  OncePerSlotJob(BillingReconcilerJob()),
];

/// The union of every action's and job's scopes - what the Function's
/// `FunctionSchema.scopes` must be, exactly.
Set<String> get requiredScopes => <String>{
  for (final action in actions) ...action.scopes,
  for (final job in scheduledJobs) ...job.scopes,
};
