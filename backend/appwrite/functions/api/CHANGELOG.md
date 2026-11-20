# Changelog

All notable changes to `api` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`api-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Fixed

- The fake SMTP server used by the mail transport tests tracks and destroys its connections on `close()` and swallows the expected EPIPE/reset after a client hangs up on a rejection, so the "5xx at RCPT" test no longer fails after completion under parallel load.
- A billing request for a team that does not exist (or that the caller is not in) is a 403 `forbidden`, not a generic 500: Appwrite's team membership list answers 404 `team_not_found` for an unknown team, which `AppwriteBillingAccess` now treats as a non-member.

### Added

- Billing: the `billing` action (`start_checkout`, `open_portal`, `update_quantity` (prorated), `entitlement`
  and the worker-only `entitlement_of`; the caller acts for itself or for a team it belongs to) over
  `paddle_billing`'s `BillingService`, `BillingReconcilerJob` (hourly, `OncePerSlotJob`: corrects the entitlement
  from Paddle and logs every divergence, never writes the ledger), `AppwriteBillingLedger`,
  `AppwriteEntitlementStore` and `AppwriteBillingAccess`; `package:api/billing_stores.dart` exports the stores for the
  `hooks` Function.
- Email: the `send_example_mail` action (mails the signed-in caller the example digest through the `Mailer`,
  rate limited, idempotent per `requestId`) and the `mail_unsubscribe` action (`requiresUser: false`; verifies a signed
  link, records the unsubscribe only on `confirm`, 400 on a bad or expired token). `/unsubscribe` on the Function's own
  domain maps to it (`routerBodyFor`), a GET shows a localised confirmation page and a POST (RFC 8058) records it;
  `FunctionResponse` can carry `html` and `headers`.
- `mailerFor`: `MailerEngine` over `AppwriteMailStore` (the `mail_deliveries` unique-row claim and `mail_suppressions`),
  `RoutingMailTransport` (direct SMTP via `package:mailer` for mail with headers, Appwrite Messaging for the rest;
  Messaging cannot set `List-Unsubscribe`), `MAIL_TRANSPORT=dry` and the `MAIL_*` Function variables. `HousekeepingJob`
  deletes `mail_deliveries` rows older than 90 days (`MAIL_DELIVERY_RETENTION_DAYS`).

### Changed

- `TeamHistoryRetentionJob` is now one `RetentionRule` (`TeamHistoryEmailRule`) run by the shared `runRetention`
  helper: same behaviour, plus a log line per run. `TeamHistoryRetentionJob.retentionFrom` is gone
  (`retentionDaysFrom`).

### Added

- Server primitives for background work, all inside the one `api` Function (no new Function):
  - the `jobs` action: the leased queue's every state change (`JobQueueEngine` over `AppwriteJobStore`, claim
    rows unique on job and attempt). Callable only by a user listed in the `JOBS_WORKER_USER_IDS` variable
    (unset means nobody); no secret travels in the body.
  - `OncePerSlotJob` (and `SlotStore`/`AppwriteSlotStore`): a scheduled job runs at most once per slot, even
    if the cron fires twice; a failed run releases its slot.
  - `RateLimiter` for unauthenticated actions: fixed windows, keyed by an HMAC of an IP or host under the
    `RATE_LIMIT_SECRET` variable, one unique row per hit. New `ActionContext.callerAddress` (the first
    `x-forwarded-for` entry) and `ActionContext.log`.
  - the retention helper: `RetentionRule`, `DeleteOlderThanRule`, `runRetention` (per-table periods, a log line
    per rule with rows and duration, a failing rule never hides the others), and `HousekeepingJob`, the example
    cron job (hourly, once per slot) that deletes expired rate-limit hits and old job slots.
- The `team_admin` action: every team operation (create, invite, accept, revoke, role change,
  removal, leave, ownership transfer, history) running `TeamEngine` on Appwrite Teams (memberships as
  `tenant_owner`/`admin`/`member` roles, never the native `owner`) and the server-only `team_invitations`
  and `team_membership_events` tables; the operation is the body's `op`. Adds `teams.read`/`teams.write`.
- The one `api` router Function, replacing the separate `delete_account` and
  `review_demo_sign_in` Functions (the Appwrite Cloud Free plan allows 2 Functions per project). It
  dispatches `{"action": "...", ...}` to a registry of actions (`lib/src/registry.dart`), takes the caller
  only from the `x-appwrite-user-id` header, enforces each action's `requiresUser`, maps errors, and runs
  registered scheduled jobs on the cron tick (`x-appwrite-trigger: schedule`; no jobs yet).
- Each action declares its own key scopes; a test asserts the Function's declared scopes are exactly their
  union.
- The `delete_account` action: deletes the calling user's own rows/files, per `backend/appwrite/schema`'s
  `TableOwnership` declarations, then the user account itself (moved from the `delete_account` package,
  behaviour and tests unchanged).
- The `review_demo_sign_in` action: exchanges a shared review code for a real session token on
  one allow-listed, admin-seeded App Review demo account, callable with no session; constant-time
  comparison plus a small fixed delay on mismatch, and a generic 401 (moved from the
  `review_demo_sign_in` package, behaviour and tests unchanged).
- `delete_account` refuses with 409 `owns_teams` (naming the teams) while the caller owns a team.
- `TeamHistoryRetentionJob`, a daily scheduled job replacing old history email snapshots by "former member"; no expiry unless `TEAM_HISTORY_EMAIL_RETENTION_DAYS` is set.

### Fixed

- The fake SMTP server used by the mail transport tests tracks and destroys its connections on `close()` and swallows the expected EPIPE/reset after a client hangs up on a rejection, so the "5xx at RCPT" test no longer fails after completion under parallel load.

- `environment: sdk:` is `^3.12.0` so the function builds on the `dart-3.12` runtime, the newest Dart
  runtime Appwrite Cloud offers.
