# backend/appwrite

Provisioning and deployment tooling for the template's Appwrite backend. The
dev backend is an Appwrite Cloud project — the template ships no local stack
(self-hosting stays possible per clone, it just isn't part of the template).
One provider directory under `backend/` — a clone adding a second
backend gets its own `backend/<provider>/` sibling. See the root `CLAUDE.md`
for how this fits into the workspace.

## Layout

- `tool/` — package `appwrite_tool`: provisioning/deployment tooling.
  - `lib/src/` — `Provisioner`, `AppwriteAdmin`/`DartAppwriteAdmin`,
    `BackendEnv` (see "Dev backend" below) and `deploy/` (staging, vendoring,
    pubspec rewriting, archiving, uploading).
  - `bin/provision.dart` — idempotent schema provisioning.
  - `bin/deploy.dart <function-id>` — stages, vendors, archives and
    deploys one Function (`api`).
  - `bin/deploy_site.dart <site-id>` — deploys a prebuilt static build to an
    Appwrite Site, see "Sites, production and promotion" below.
  - `bin/promote.dart --production` — schema + Functions + Sites to the
    production project from a release tag, dry run first.
  - `bin/api_keys.dart` — the scoped API keys: creation checklist and
    `--audit`.
  - `bin/seed_review_demo_account.dart <email>` — idempotently seeds the
    App Review demo account — see "App Review demo access"
    below and `apps/app/README.md`.
- `adapters/` — package `appwrite_adapters`: the Appwrite implementations
  of `core/contracts/auth`/`data`/`teams`/`jobs`'s interfaces (Flutter,
  via `appwrite` — this app's default backend wiring).
- `schema/` — package `appwrite_schema`: the declarative schema `tool/`
  and `functions/api` share.
- `functions/hooks/` — the `hooks` Function: public inbound webhooks, routed by path; its one hook is
  Paddle's billing webhook, see "Billing" below.
- `functions/api/` — the one `api` router Function, one
  package: `lib/src/actions/<name>/` holds each action (its own module,
  gateway, validation and tests under `test/actions/<name>/`), see "Server-side
  operations: the `api` Function" below. The App Review demo sign-in
  is its `review_demo_sign_in` action — see "App Review demo
  access".

## Server-side operations: the `api` Function

**Why one Function.** Since 2026-01-08 Appwrite Cloud's Free plan allows **2
Functions per project**; creating a third fails with `403
additional_resource_not_allowed`. Decision (2026-10-01): no paid
plan for development and no self-hosting: the template and low-revenue
clones stay on the Free plan. So the schema declares **at most 2 Functions**
(`maxFunctions`; a test in `backend/appwrite/schema` fails with a message
pointing here): the `api` router, and **`hooks`** (public, unauthenticated
inbound webhooks, signature-verified per hook and routed by path; its first
hook is `/paddle`).

**The router convention.** A client calls `api` with a JSON body
`{"action": "<snake_case_name>", ...fields}` through `ApiClient`
(`backend/appwrite/adapters`, the only place a Function id appears). The router
(`functions/api/lib/src/api_router.dart`) authenticates, dispatches and maps
errors; an action never does:

| status | meaning |
| --- | --- |
| 400 | body is not a JSON object with a string `action`, or the action's own validation failed |
| 401 | the action needs a signed-in caller and there is none |
| 404 | unknown action |
| 500 | the action threw; the body is the action's generic `failureMessage`, the cause is only in the Function log |

The caller's identity is **always** the execution's `x-appwrite-user-id`
header, never the body. The Function's `execute` role is `any` (the
`review_demo_sign_in` action must work with no session), so each action
declares `requiresUser` and the router enforces it before the action runs.
Scheduled work: the Function has one cron schedule (every 5 minutes,
`apiCronSchedule`); on that tick (`x-appwrite-trigger: schedule`) the router
runs each registered `ScheduledJob` that is due, once per slot, so a job must
be idempotent per slot (`slot` is passed in). `scheduledJobs` holds the team
history retention job (a no-op until configured; see "Team tenancy") and `HousekeepingJob` (wrapped in
`OncePerSlotJob`; see "Background work"); a clone appends its own. **Unverified live:** that the `x-appwrite-trigger` header carries
`schedule` on a cron execution; check with the first registered job.

**Least privilege.** A Function has one key scope set, so each action declares
the `scopes` it needs and `FunctionSchema.scopes` for `api` must be exactly
their union (`functions/api/test/scopes_test.dart` fails on any difference, in
either direction). The cost: an action runs with the union of all scopes, so
keep actions' scopes narrow and the code, not the key, is the boundary.

**Adding an action.**

1. Create `functions/api/lib/src/actions/<name>/` with the action's
   logic behind a gateway interface (as `delete_account` does), plus
   `<name>_action.dart` implementing `ApiAction` (`name`, `requiresUser`,
   `scopes`, `failureMessage`, `run`). The action validates its own body
   fields and returns `FunctionResponse`s.
2. Add tests under `functions/api/test/actions/<name>/` (fake gateway).
3. Append it to `actions` in `functions/api/lib/src/registry.dart`.
4. Add its scopes to `api`'s `scopes` in `backend/appwrite/schema` (the scopes
   test tells you what is missing).
5. Add the caller: a method using `ApiClient.call('<name>', fields: ...)`.
6. `dart run bin/deploy.dart api`; add a `CHANGELOG.md` line in `api`.

Never add a Function for an operation. Environment variables an action needs
(like `REVIEW_DEMO_CODE`) are variables of the `api` Function, shared by all
actions: prefix them with the action's name.

## Dev backend: an Appwrite Cloud project

Appwrite Cloud's free tier is the dev backend. Cloud serves real HTTPS, so the
app and the tooling need no self-signed-certificate handling, and Cloud sends
real emails (email-code sign-in works end to end).

Prerequisite: the Appwrite CLI (`npm i -g appwrite-cli`). `appwrite login` is
interactive — run it in a real terminal, not from a script or an agent.

1. **Create a project** in the Cloud console, region **Frankfurt**
   (endpoint `https://fra.cloud.appwrite.io/v1`). Note its project ID.
2. **Add a web platform for `localhost`**, so a browser (or the web build)
   served from `localhost` may call the API:

   ```
   appwrite project create-web-platform --project-id <project-id> \
     --platform-id localhost --name localhost --hostname localhost
   ```

3. **Create an API key** with the scopes under "Configuration" below and write
   it straight into the gitignored `backend/appwrite/tool/.env.local` (see
   `backend/appwrite/tool/.env.example`). **The CLI redacts secrets in its
   output unless `--show-secrets` is passed** — without it, the key comes back
   as a ~21-character placeholder that fails with `api_key_invalid`. Pipe the
   result into the file instead of printing it.

   **`appwrite-cli` 27.0.0 and later have no `project create-key`** (only
   `create-ephemeral-key`, at most one hour), and fail with a misleading
   `unknown flag: --project-id`. Run this one command through **26.1.0** via
   `npx`. It uses the same `appwrite login` session as your installed CLI, and
   its `--scopes` takes one value per flag. Verified 2026-10-01 (26.1.0 for the
   key, 28.1.0 for `login`) against the Cloud project, and the integration tests
   in step 4 passed with the result:

   ```
   ( set -o pipefail; umask 077
     s=(); for x in project databases tables collections documents attributes \
         columns indexes functions buckets files users; do
       s+=(--scopes "$x.read" --scopes "$x.write"); done
     key="$(npx -y appwrite-cli@26.1.0 project create-key \
       --project-id <project-id> --key-id dev-tool --name dev-tool "${s[@]}" \
       --json --show-secrets | jq -r .secret)" && [ ${#key} -gt 100 ] &&
     printf 'APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1\nAPPWRITE_PROJECT_ID=<project-id>\nAPPWRITE_API_KEY=%s\n' \
       "$key" > backend/appwrite/tool/.env.local && echo "ok, key length ${#key}" )
   ```

   `umask 077` only applies to a new file. If `.env.local` already existed,
   run `chmod 600 backend/appwrite/tool/.env.local` afterwards. The length
   check catches the redacted placeholder before it overwrites a working file.

   To read an existing key's value the same way, use `appwrite project
   get-key --project-id <project-id> --key-id <key-id> --json --show-secrets`
   (again piped, never echoed).
4. **Provision and deploy:**

   ```
   cd backend/appwrite/tool
   dart run bin/provision.dart
   dart run bin/deploy.dart api
   ```

   `bin/provision.dart` also **deletes every Function in the project that the
   schema does not declare** (listed first under `--dry-run`): the schema is
   the source of truth, and on the Free plan a leftover Function holds a slot
   the next one needs (see below). Deleting drops its deployments and
   variables. A Function the schema declares is never deleted. A project that
   still has the old `delete_account` and `review_demo_sign_in` Functions
   needs this to create `api`; afterwards rerun
   `bin/seed_review_demo_account.dart <email>` (its variables lived on the
   deleted Function).

`bin/provision.dart` also creates the `app_config` `default` row the app's
version check reads, declared as `seedRows` in
`backend/appwrite/schema`. Its `minSupportedVersion` is `0.0.0`, the "nothing is
blocked" value: the check blocks only an app *older* than that, and no version
is, so it passes for the template's app and any clone. Raise it in the console to
force an update (set `updateUrlIOS`/`updateUrlAndroid`/`updateUrlWeb` and `message`
alongside). Provisioning only creates the row when it is absent and never
overwrites an existing one, so your edits survive every re-run. A clone that has
not provisioned yet is also fine: the app treats an absent row as "not blocked".

`bin/provision.dart` also disables the project's unused auth methods on every
run — see "Auth methods this project must run with disabled" below. Then,
from the repo root: `dart run melos run test:integration` and
`dart run melos run test:integration:backend_appwrite`.

**Functions run on the `dart-3.12` runtime**, the newest Dart runtime Appwrite
Cloud offers. A cold-start execution can take longer than the console-default
15 s function timeout, so `backend/appwrite/schema`'s
`defaultFunctionTimeoutSeconds` is 30.

### The `.env.local` is shared across every worktree

Every issue branch lives in its own `.worktrees/<N>/` (see root `CLAUDE.md`),
and `backend/appwrite/tool/.env.local` is gitignored — so if it lived inside a
worktree's own working tree, `git worktree remove` would delete it. Instead,
`BackendEnv.load` (used by `bin/provision.dart`, `bin/deploy.dart`,
`bin/seed_review_demo_account.dart` and the integration tests) looks in the
current directory first, then falls back to the **main checkout's own**
`backend/appwrite/tool/.env.local`, found via `git rev-parse --git-common-dir`
(identical for the main checkout and every linked worktree; see
`findSharedBackendDir` in `tool/lib/src/repo_root.dart`). Write the file once
in the main checkout and every worktree finds it.

## Configuration

`bin/provision.dart` and `bin/deploy.dart` read `APPWRITE_ENDPOINT`,
`APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY` from environment variables or
`backend/appwrite/tool/.env.local` (gitignored — see the setup above and
`backend/appwrite/tool/.env.example`). Never passed as command-line
arguments, never committed.

The API key needs these 26 scopes (read + write for each): `project.*` (`Provisioner` disabling unused auth methods needs project-level scope, not
just the resource-level ones below), `databases.*`, `tables.*`,
`collections.*`, `documents.*`, `attributes.*`, `columns.*`, `indexes.*`,
`functions.*`, `buckets.*`, `files.*`, `users.*`, `providers.*` (the mail SMTP provider; only
needed when `.env.local` configures mail). Appwrite's scope names for
`TablesDB` are inconsistent across its own API surface — both `tables.*`
**and** `collections.*` are checked at different points, found by hand
hitting `general_unauthorized_scope` errors with only one of the two granted.

## Team tenancy

The `team_admin` action of the `api` router runs `core/contracts/teams`'s `TeamEngine` against Appwrite Teams and
two tables, and `AppwriteTeamService` (in `adapters/`) calls it through `ApiClient` for every team operation (the
operation is the body's `op`). See `apps/app/README.md` "Teams and
team-scoped rows" for the design and why a Function is needed (Appwrite Teams can't keep "exactly one owner").
What this backend needs:

- **Deploy it** with the router (`bin/deploy.dart api`); it is not a Function of its own (the Free plan allows two).
  It identifies
  the caller from the execution's own `x-appwrite-user-id`, never the body, and refuses a caller whose email is not
  verified (invitations are matched by email; the email-code sign-in verifies it).
- **Scopes.** The action declares `users.read`, `teams.read`, `teams.write` and the tables/documents scopes, which
  are part of `api`'s `FunctionSchema.scopes` (`scopes_test.dart` keeps them equal). The provisioner's own key may
  need `teams.*` too to create a Function that holds them; if provisioning answers `general_unauthorized_scope`, add `teams.read`/`teams.write` to that key
  (`ApiKeySchema` `provisioner`) and re-run.
- **Tables.** `team_invitations` and `team_membership_events` are `serverOnly` (`TableSchema.serverOnly`):
  provisioning grants no client any permission on them. `team_notes` is the example team-scoped table (a clone
  replaces it with its own).
- **Nobody holds Appwrite's native `owner` role.** The contract's owner holds `tenant_owner` (plus `admin` and
  `member`), so a client can't call the Teams SDK to add owners, demote the owner or delete a team that
  the `team_admin` action manages. A team a client creates with the Teams SDK directly is outside the contract: it has no
  history and no invariant, and affects only its creator.
- **Native memberships are the function's to read.** Verified live: a `tenant_owner` client's own
  `Teams.listMemberships` returns the *other* members with an **empty `userId`** (Appwrite's membership privacy hides
  member details from anyone who is not a native `owner`). So nothing in the adapters lists memberships through the
  Teams SDK; everything reads through the `team_admin` action (API key), whose `Membership.membershipId` carries the
  native ID the live test needs.
- **What stops a client bypassing the Function** (Appwrite server source, tag 2.3.0,
  `src/Appwrite/Platform/Modules/Teams/Http/Memberships/`): `Update.php` lines 90-117 and `Create.php` lines 264-267
  allow a membership change only to a caller holding the exact role `team:<id>/owner`, an API key or a privileged
  user; anyone else gets `user_unauthorized` (401). Nobody holds the native `owner` role of a team `team_admin`
  manages, so a client's raw call is always refused. **Client invitations can't happen at all:** the
  `createMembership` route is labelled `auth.type: invites` (`Create.php` line 61), and the provisioner disables the
  `invites` auth method, so Appwrite answers every client invitation with `user_auth_method_unsupported`
  (501) before the route's own code runs: before its SMTP check, its owner check, and before any invitee user is
  created. **Keep `invites` disabled**: re-enabling it would make the owner check (lines 264-267) the only barrier,
  and would let a refused raw call leave an unverified user behind. The live test asserts both refusals:
  `updateMembership` with `user_unauthorized`, `createMembership` with `user_auth_method_unsupported`.
- **Account deletion**. The `delete_account` action asks `TeamEngine.ownedTeams` first and **refuses with
  409 `{"error": {"code": "owns_teams", "message": ..., "teams": [names]}}` while the caller owns a team**, before
  deleting anything; `ApiClient` carries it as an `AppwriteException`, `AppwriteAuthService` maps it to
  `AuthOwnsTeamsError`. An admin or member deletes; Appwrite removes their memberships, the history stays. The
  action's scopes gain `teams.read` (already in the union).
- **Retention of the history's email snapshots**. `TeamHistoryRetentionJob` (a `ScheduledJob`, registered in
  `scheduledJobs`, daily on the cron tick) replaces the `actorEmail`/`subjectEmail` of every
  `team_membership_events` row older than the period by `former member` (`TeamEngine.redactEmailsOlderThan` ->
  `AppwriteTeamStore.redactEventEmails`; an `at_key` index backs the `at < cutoff` query). The period is the `api`
  Function variable `TEAM_HISTORY_EMAIL_RETENTION_DAYS`, **unset in the template = no expiry**; a clone enables it
  by adding `'TEAM_HISTORY_EMAIL_RETENTION_DAYS': '365'` to the `api` `FunctionSchema.variables` (12
  months, i.e. 365) and re-running the provisioner. A set but invalid value fails the job visibly (the tick answers
  it under `failed`). `team_invitations` rows also hold the invitee's email and are not touched by this job; a clone
  that needs them gone adds its own job. The job is a `RetentionRule` run by the shared retention helper (see
  "Background work"), so it logs its rows and duration like every retention job. **Unverified live:** the `at`
  range query against Appwrite and the cron trigger; run the job once with a short period against the dev project
  to check.

## Background work: queue, slots, rate limits, retention

Four primitives for any clone that does background work, all inside the one `api` Function (no new Function; the
schema test enforces the 2-Function limit). **TablesDB has no compare-and-set update** (no "set X where it is still
Y"), so each is built on one atomic operation Appwrite does give: *inserting a row that violates a unique index is
refused with 409*. Four `serverOnly` tables back them (`jobs`, `job_claims`, `job_slots`, `rate_limits`); re-run
`provision` on an existing project to create them.

### The leased job queue (`core/contracts/jobs`, the `jobs` action)

`JobQueue`: `enqueue(NewJob(type:, priority:, maxAttempts:, availableAt:))`, `claim(workerId:, leaseFor:, types:)`,
`heartbeat`, `complete`, `fail`, `release`, `status`. Priority bands are `high`/`normal`/`low` (a worker claims the
best band, oldest first). `JobQueueEngine` is the one implementation of the rules over a `JobStore`;
`FakeJobQueue` runs them in memory for tests; `AppwriteJobStore` (in `api`) runs them on the tables.

**Why claim rows.** A lease can't be "set `leasedBy` where it is empty", so a claim is an *insert*: `job_claims` holds a
row per attempt, unique on (`jobId`, `attempt`) (the row ID is `<jobId>_<attempt>` too). Concurrent claimers of a job
all try to insert attempt `n + 1`; the index lets exactly one through, the rest move to the next job. Everything else
is derived from the claim rows, never stored twice: a job is `running` while its latest claim is active with an
unexpired lease, `queued` when that lease expired (a crash) or the attempt failed/was released and attempts remain,
`dead` when the non-released claims reach `maxAttempts`, `succeeded` when the latest attempt completed. `jobs.status`
is only a cache that narrows the claim query; a crash between two writes cannot corrupt the queue because the claims
are the truth, and a stale cache heals on the next claim.

**Stale workers.** A result, heartbeat or failure carries its attempt (the `JobLease`) and is written to *that
attempt's* claim, after checking it is still the job's latest claim, held by that worker and active; the check runs
again after the write. A worker that lost its lease gets `JobLeaseLostError` (409 `lease_lost`), and its write lands on
a claim the status derivation ignores, because only the latest attempt counts. **Delivery is at least once:** a
worker stalled past its lease may still have done the work, so handlers must be idempotent.

**One action, worker auth.** Every state change goes through the `jobs` action (`op` = the method name; `JobWire`
is the JSON). It is called by *workers*, including ones outside Appwrite (a separate scanner service, say), not by app users, so
`requiresUser` is true and the router's unforgeable `x-appwrite-user-id` must be in the Function variable
`JOBS_WORKER_USER_IDS` (comma separated; **unset means nobody**, every call is 403). The decision: a **worker
identity** (a dedicated Appwrite user the worker signs in as) rather than a shared secret in the body, because an
execution's request body is stored in its log, so a secret there leaks to anyone who can read executions; a user is
revocable by deleting it or its sessions, and needs no new auth mechanism in the router. A worker outside Appwrite
holds the credentials of its worker user (or mints a short-lived JWT for it with a key scoped to `users.write`), and
calls `ApiClient` (`AppwriteJobQueue.withApi(ApiClient.withExecutor(...))` over its own HTTP executor). Code inside
the Function (another action, a scheduled job) builds a `JobQueueEngine` over `AppwriteJobStore` directly and skips
HTTP. Leases are capped at one hour per call.

### Once-per-slot scheduled jobs (`OncePerSlotJob`)

Appwrite cron can fire twice or late. Wrap a `ScheduledJob` as `const OncePerSlotJob(MyJob())` in `scheduledJobs`:
before running it claims `(job name, slot)` in `job_slots` (unique), so a second fire of the same slot does nothing,
including two concurrent fires. If the job throws, the claim is released so a re-delivered tick can retry, and the
router reports the job as failed. The example is `HousekeepingJob` (hourly, registered wrapped). `job_slots` rows are
swept after 30 days (`JOB_SLOTS_RETENTION_DAYS` overrides).

### The rate limiter (`RateLimiter`)

For unauthenticated actions: `RateLimiter.forContext(context).check(scope:, key:, limit:, window:)` returns
`allowed`/`remaining`/`retryAfter`; key it on `context.callerAddress` (the first `x-forwarded-for` entry) or a host.
Counting is a unique row per hit (`keyHash`, `windowStart`, `hit`): a call tries hit `n + 1`, `n + 2`, ... until an
insert wins or the limit is passed, so concurrent callers never share a number and the limit is exact (cost: up to
`limit` inserts in a burst, so keep limits small). **What is stored and for how long:** only `HMAC-SHA-256(secret,
scope + key)`, never the address or host (the secret, `RATE_LIMIT_SECRET`, is a Function variable you set; without it
the limiter refuses to run, because an unkeyed hash of an IPv4 address is reversible), the window start, the hit
number and the window's end. A row is useless after its window ends and `HousekeepingJob` deletes it hourly, so a key
is retained for **at most the window plus one hour**. **Unverified live:** that the platform sets `x-forwarded-for`
trustworthily (its first entry may be client-supplied); treat it as a hint and do not limit by it alone anything that
must hold. The template does not wire the limiter into `review_demo_sign_in` (it has Appwrite's own execution rate
limit); a clone adds the call where it needs it.

### The retention helper (`runRetention`)

`RetentionRule` (`name`, `periodFrom(env)`, `apply(...)` returning rows changed) plus `runRetention(context, rules)`:
resolves every period first (a set but invalid one throws, so a typo fails visibly), skips rules with no period (keep
forever), runs each rule in isolation (a failing rule never hides the others), **logs one line per rule: rows
changed, duration and any error**, and throws at the end if any failed so the router reports the job as failed. A rule
must be idempotent. `DeleteOlderThanRule(table:, column:, envKey:, defaultPeriod:)` deletes the rows of a table whose
UTC ISO-8601 `column` (indexed) is older than the period, at most 5000 rows per run (a backlog is worked off over
several runs). `TeamHistoryRetentionJob` is one such rule (it redacts instead of deleting), so this helper is the pattern. A clone adds a rule to `HousekeepingJob`, or a new job, for its own tables; the template leaves
finished-`jobs` and `job_claims` retention to the clone (what to keep is policy; delete a job's claims together with
the job).

### Optimistic concurrency (`DocumentRepository.update(expectedVersion:)`)

`Document.version` is an opaque token that changes on every write; pass the one you read as `expectedVersion` and a
stale update is refused with `DataConflictError` (the fake and the Appwrite adapter both do). On Appwrite the version
is the row's `$updatedAt` (no extra column to maintain, and any writer, including a Function, changes it). **Limit:**
TablesDB can't make the check and the write one step, so the adapter reads, compares, then writes: it closes the
realistic window (a form saved minutes after another save) but two saves that both pass the read within the same few
milliseconds can both win. State that needs a hard guarantee must change through an `api` action over a unique row,
as the queue does. 409 from Appwrite (a taken row ID, a unique-index violation) is also mapped to `DataConflictError`.

**Live check** (the reviewer runs it; it needs the dev project): from `backend/appwrite/adapters`,
`fvm flutter test --tags integration --run-skipped test/integration/appwrite_server_primitives_integration_test.dart`
(its own file: the teams suite also deploys `api`, and two concurrent deploys collide). It provisions,
allow-lists a worker user in `JOBS_WORKER_USER_IDS`, deploys `api` and proves the double claim, the lease takeover and
stale write, the 403 for a non-worker and the stale `expectedVersion`.

## Email: transactional and notification mail

The app's own email (a digest, a receipt) goes through `core/contracts/mailing`, never from a client: it is sent
inside `api` actions and scheduled jobs (no new Function; the schema test enforces the 2-Function limit). Appwrite
still sends its own sign-in codes; this is for everything the app owns.

### The contract and the engine

`Mailer.send(MailMessage(idempotencyKey:, recipient:, templateId:, locale:, data:, headers:))` returns a
`MailDeliveryResult` (`status`: pending, accepted, delivered, rejected, failed, bounced, suppressed; `replayed`;
`providerMessageId`; `detail`). `MailerEngine` is the one implementation of the rules over a `MailStore` and a
`MailTransport`; `FakeMailer` runs the same engine in memory and records sent mail (`FakeMailer.sent`), so a test
sees the real idempotency, suppression and header rules. In `api`, `mailerFor(context)` builds the engine over the
Appwrite tables and the transport the Function variables select; a clone sends from its own action or job with it
(`send_example_mail` is the worked example: look the recipient up by the router's user ID, rate limit, send).

**Templates are Dart, not slang.** `apps/app`'s i18n is generated Flutter code from `apps/app/lib/i18n/*.i18n.json`;
the `api` Function is pure Dart built from path dependencies without the app, so a template there would need
Flutter or a copy step. `MailTemplate` holds a text per locale (`en` base, `de`), uses slang's `{name}` placeholders
and its base-locale fallback (`MailLocale.parse('fr') == en`), and `MailCatalog` refuses at construction a template
that lacks a locale or whose placeholders differ between locales (the parity slang's tooling gives the app). Values
are HTML-escaped in the html body and a CR or LF in a subject is flattened.

### Appwrite Messaging cannot do it alone: two transports

Read from `dart_appwrite` 29.0.0 (`Messaging`, `Message`), not guessed:

| need | Appwrite Messaging | decision |
| --- | --- | --- |
| SMTP provider | `createSmtpProvider` (host, port, user, password, encryption, from) | `appwrite_tool` creates `mail-smtp` from `.env.local` |
| recipients | users, topics, targets, cc/bcc | `users: [userId]` (the user's own email target; no address passed) |
| custom headers (`List-Unsubscribe`) | **none**: `createEmail` has subject, content, html, recipients, attachments, schedule only | **cannot be done through Messaging** |
| delivery status | `Message.status` (draft, processing, scheduled, sent, failed), `deliveredTotal`, `deliveryErrors` | read by `Mailer.status` (accepted -> delivered / failed) |
| bounces | **none** reported | see "Bounces" |
| plain-text part | none (html or text, not both) | an html mail goes as html only |

So `RoutingMailTransport` (the default `MAIL_TRANSPORT=auto`) sends **a mail with headers, i.e. every
non-transactional mail, directly over SMTP** with `package:mailer` (MIT; its transitive packages are MIT or
BSD-3-Clause, checked by `licence-check`), and **a mail without headers (transactional) through Appwrite
Messaging**. The trade-off: SMTP credentials live twice, as the Messaging provider and as `api` variables
(`provision` writes both from one `.env.local`), and direct SMTP depends on the Function runtime being allowed
outbound SMTP (**unverified live**: no SMTP was configured on the dev project). A clone that only wants one
path sets `MAIL_TRANSPORT=smtp` (everything direct, transactional included) or `messaging` (then a mail that needs
headers is refused, never sent without them). `dry` records the delivery and sends nothing (the live tests use it).

**Delivery result honestly.** SMTP answers synchronously: `250` is `accepted`, `5xx` is `rejected` (with the server's
reason), `4xx`, a refused connection or a failed login is `MailNotSentException` (a retry may send). It can never
say `delivered`. **Bounces:** neither path reports an asynchronous bounce. The contract carries `bounced` and
`Mailer.recordBounce(idempotencyKey)` (marks it and suppresses the recipient for every subscription); a clone
wires its provider's bounce webhook to it through the reserved `hooks` Function.

### Idempotency: a retried send never mails twice

`mail_deliveries` (`serverOnly`) is unique on a SHA-256 of the idempotency key, and the row ID derives from it too:
**claiming is inserting the row**, a 409 means a send with that key exists, and the existing result is returned with
`replayed: true`. Of any number of concurrent or retried sends exactly one reaches the transport. It is
**at most once**: a crash between the claim and the outcome leaves a `pending` record that a retry does not send
again (use a new key to force it); only a transport that proves nothing left (`MailNotSentException`) releases the
claim. The Messaging message ID derives from the key as well, so even a raced create is a 409 and reads the existing
message. The row holds no address and no body. `HousekeepingJob` deletes rows older than 90 days
(`MAIL_DELIVERY_RETENTION_DAYS`): after that a send with the same key would mail again.

### One-click unsubscribe

Every non-transactional template (`MailTemplate.subscription` set) gets a footer link and the headers
`List-Unsubscribe: <url>` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 2369 and RFC 8058); a
caller cannot set them. The URL is `MAIL_UNSUBSCRIBE_BASE_URL` plus `?t=<token>`, where the token is
`UnsubscribeLinks`' HMAC-SHA-256 under the secret `MAIL_LINK_SECRET` (the approach of `RateLimiter`; `provision`
generates the secret): a payload of **one user ID, one subscription, the locale and an expiry** (60 days,
`MAIL_LINK_TTL_DAYS`). The signature is checked in constant time before the payload is read, so nothing can widen
the scope. Rotating the secret invalidates every outstanding link.

The `mail_unsubscribe` action has `requiresUser: false` and is the only authority check: it reads nothing from the
body but the token and two flags. Without `confirm: true` it only checks the link (state `confirm`), so a mail
scanner's GET unsubscribes nobody; `confirm: true` records a row in `mail_suppressions` (unique per user and
subscription), idempotently. A bad, forged or expired token is a 400 and writes nothing.

**How the person sees it.** RFC 8058 needs a POST to the URL in the header, and a static site cannot take one, so the
URL must be a server endpoint: **the `api` Function's own domain, path `/unsubscribe`** (`MAIL_UNSUBSCRIBE_BASE_URL`
= `https://<function domain>/unsubscribe`; add the domain in the console). `lib/src/http_entry.dart` turns a
request there into a `mail_unsubscribe` call asking for HTML: a GET shows a small localised page with a confirm
button (no script; `Cache-Control: no-store`, `Referrer-Policy: no-referrer`, a CSP), the button and an RFC 8058 mail
client POST, and the answer is a "you are unsubscribed" page. No app route and no website page is needed. A clone that
prefers its own page calls the action as JSON through `ApiClient`. **Unverified live:** that Appwrite serves a
Function domain's `text/html` response and passes `req.path`/`req.query` as the code assumes; open one real link
once. The recipient is told nothing about *which* address was unsubscribed.

### No tracking

The template adds **no tracking pixel, no link rewriting and no open or click tracking**; the only link the engine
ever puts into a mail is the unsubscribe one (tests assert no `<img` and one `href`). Adding tracking would need
consent in the EU (under the ePrivacy rules and the GDPR), so it is a clone's deliberate decision.
Also configure SPF, DKIM and DMARC for the sending domain at the SMTP provider; Gmail and Yahoo require them for
one-click unsubscribe.

### Configuration

`.env.local` (gitignored, see `.env.example`): `MAIL_SMTP_HOST`, `MAIL_SMTP_PORT` (587 STARTTLS, 465 implicit TLS),
`MAIL_SMTP_USER`, `MAIL_SMTP_PASSWORD`, `MAIL_FROM`, `MAIL_FROM_NAME`, `MAIL_UNSUBSCRIBE_BASE_URL`. `provision`
creates the Messaging provider `mail-smtp` and the `api` variables of the same names (the password and
`MAIL_LINK_SECRET` as secret variables), each only when absent, never printing a credential. **Without
`MAIL_SMTP_HOST` and `MAIL_FROM` it skips mail and says so** (`Note: mail: skipped ...`); the link secret is
generated either way. To change the SMTP settings later delete the provider and the variable in the console and
re-provision. The `api` key scopes gain `messages.read`/`messages.write`; the `provisioner` key gains
`providers.read`/`providers.write` (re-create it if you scoped it). Two `serverOnly` tables, `mail_deliveries` and
`mail_suppressions`: re-run `provision` on an existing project.

**Live check** (the reviewer runs it; no SMTP needed for most of it): from `backend/appwrite/adapters`,
`fvm flutter test --tags integration --run-skipped test/integration/appwrite_mail_integration_test.dart`. It sets
`MAIL_TRANSPORT=dry` and a known `MAIL_LINK_SECRET` on the `api` Function (and re-provisions a fresh secret at the
end), deploys `api`, and proves the retried send (one row, `replayed`), the unsubscribe with no session (only on
`confirm`, idempotent, suppresses the next send) and the rejection of a tampered, wrong-secret and expired token.
The test that sends a real mail skips itself (in its body, so `--run-skipped` does not force it) unless `.env.local`
also has `MAIL_SMTP_HOST`, `MAIL_FROM` and `MAIL_TEST_RECIPIENT`. The last test creates an execution with
`path: /unsubscribe?t=...` and `GET`: a garbage token must give a 400 `text/html` page and a fresh valid one the 200
confirmation page without unsubscribing, which proves `main.dart`'s path/query mapping and the HTML response. That a real
custom or default Function *domain* routes to the same code is a deploy-time check (open one real link).

## Billing: a merchant of record, a webhook ledger and entitlements

Web billing for a SaaS clone. The provider is **Paddle Billing**, the template's default merchant of record (Polar is the documented fallback, a clone swapping it writes its own adapter next to
`backend/paddle`). Four pieces, none of them a new Function beyond the reserved second one:

| piece | where |
| --- | --- |
| the contract (`Billing`, `Entitlement`, the ledger, the engine, the reconciler, `FakeBilling`) | `core/contracts/billing` |
| the Paddle adapter (signature, event parser, API client, `BillingService`) | `backend/paddle` (package `paddle_billing`) |
| the webhook, `POST /paddle` | the **`hooks`** Function (`functions/hooks`) |
| checkout, portal, quantity, the entitlement read, and the reconciler | the `billing` action and `BillingReconcilerJob` of `api` |

```
Paddle --POST /paddle--> hooks: verify signature over the raw bytes
                           -> BillingEngine: append ledger row (billing_events)   [first]
                                             then update billing_entitlements      [only if the row was new]
app --billing action--> api: start_checkout / open_portal / update_quantity / entitlement  (acts as the caller)
api cron (hourly) -> BillingReconcilerJob: compare Paddle with ledger + entitlements, correct the entitlements, log divergences
```

### Paddle facts this is built on (from developer.paddle.com, read 2026-10-02)

- **Signature** (<https://developer.paddle.com/webhooks/signature-verification>): header `Paddle-Signature:
  ts=<unix>;h1=<hex>` (several `h1` during a secret rotation); the signed payload is `<ts>` + `:` + **the raw request
  body, untouched**; HMAC-SHA256 with the notification destination's secret key, hex. Paddle's SDKs reject a timestamp
  more than 5 seconds old (the Node SDK source confirms the key is used as-is, `paddle-node-sdk`
  `webhooks-validator.ts`). `PaddleSignature` checks `|now - ts| <= PADDLE_SIGNATURE_TOLERANCE_SECONDS` (default **60**,
  not 5: a cold-started Function can be slow; the unique event ID, not the clock, is the replay defence).
- **Envelope** (<https://developer.paddle.com/webhooks/overview>): `event_id`, `event_type`, `occurred_at`,
  `notification_id`, `data`. The `subscription.*` events carry the whole subscription entity
  (<https://developer.paddle.com/webhooks/subscriptions/subscription-updated>): `created`, `activated`, `updated`,
  `trialing`, `past_due`, `paused`, `resumed`, `canceled`, `imported`. The parser reads them all the same way. Every
  other type (`transaction.completed`, `customer.*`, ...) is a `recorded` ledger row with no effect.
- **Subscription entity** (<https://developer.paddle.com/api-reference/subscriptions/get-subscription>): `id`, `status`
  (`active`, `canceled`, `past_due`, `paused`, `trialing`), `customer_id`, `items[].{status, quantity, price.id}`,
  `current_billing_period.{starts_at, ends_at}`, `next_billed_at`, `canceled_at`, `scheduled_change.{action,
  effective_at}` (`pause`, `cancel`, `resume`), `custom_data`, `updated_at`.
- **Checkout** (<https://developer.paddle.com/api-reference/transactions/create-transaction>): `POST /transactions` with
  `items[{price_id, quantity}]`, `custom_data`, optional `customer_id`; the answer's `checkout.url` is the link to send
  the buyer to (the domain must be an approved one in the Paddle dashboard). A transaction's `custom_data` is copied to
  the subscription it creates (<https://developer.paddle.com/build/transactions/custom-data>): that is how the owner,
  `custom_data.owner` = `user:<id>` or `team:<id>` (the key's name is this template's own), reaches the webhook.
- **Quantity** (<https://developer.paddle.com/api-reference/subscriptions/update-subscription>): `PATCH
  /subscriptions/{id}` with the **complete** `items` list (an omitted item is removed) and the required
  `proration_billing_mode`; the template uses `prorated_immediately` (the others are `prorated_next_billing_period`,
  `full_immediately`, `full_next_billing_period`, `do_not_bill`). `PaddleApi.updateQuantity` reads the subscription first
  so the call keeps every item.
- **Portal** (<https://developer.paddle.com/api-reference/customer-portals/create-customer-portal-session/>): `POST
  /customers/{customer_id}/portal-sessions`, optional `subscription_ids`; the answer's `urls.general.overview` is an
  authenticated, temporary link (never stored or cached).
- **Base URLs** (<https://developer.paddle.com/api-reference/overview>, <https://developer.paddle.com/sdks/sandbox/>):
  live `https://api.paddle.com`, sandbox `https://sandbox-api.paddle.com`. A key is `pdl_live_apikey_...` or
  `pdl_sdbx_apikey_...` (<https://developer.paddle.com/api-reference/about/authentication>), sent as `Authorization:
  Bearer`; `paddleBaseFor` picks the base **from the key** and refuses any other shape, so a live key is never used by
  accident. Errors: `{"error": {"type", "code", "detail"}}`
  (<https://developer.paddle.com/api-reference/about/errors>).
- **Not read from the docs, so unverified:** the exact field list of `transaction.*` payloads (never parsed), whether a
  subscription item can be `status: inactive` while another is the live one (the mapper takes the first `active` or
  `trialing` item, else the first), the page size / `meta.pagination` of `GET /subscriptions` beyond `has_more` and `next`
  (the client follows those two), and whether `PATCH` echoes `scheduled_change`.

### The raw body (a signature fails on a re-serialised body)

The Dart runtime's `RuntimeRequest` (open-runtimes, `runtimes/dart/versions/latest/src/function_types.dart`, read
2026-10-02) keeps the body as **`bodyBinary`** (the bytes the runtime read off the socket) and derives
`bodyText = utf8.decode(bodyBinary)` and `bodyJson = jsonDecode(bodyText)` on access. So the runtime does **not**
re-serialise: `bodyBinary` (and `bodyText` for valid UTF-8) are the sender's bytes, and only `bodyJson` is lossy.
`hooks`' `rawBodyOf` reads `bodyBinary` (falling back to the bytes of `bodyText`, never to `bodyJson`) and hands the hook
those bytes. Proven twice: `functions/hooks/test/raw_body_test.dart` models the runtime's request and shows that a body
with odd spacing, a `1` escape and a trailing newline verifies when read as bytes and fails when re-serialised from
`bodyJson`; and the live suite below POSTs such a body through a real execution and the real runtime and gets a 200.
**Unverified:** that a request arriving on the Function's *own domain* (what Paddle sends) is passed to the runtime
without a proxy rewriting it; the live suite goes through `createExecution`. Send one sandbox event through the domain once
(Paddle dashboard "Notifications" → send a test event) and look for a 200.

### The ledger: honest append-only

`billing_events` (`serverOnly`) has one row per **change** of a provider event, unique on `ledgerKey`: the event ID when
the event means one change, `<event id>#1`, `#2`, ... when it means several (a `subscription.*` event is always two: the
state and the scheduled change). An event with no effect on any entitlement is one `recorded` row. A row holds the event
type, kind, `occurredAt`, `receivedAt`, what the event said about the subscription (status, quantity, plan, owner) and a
**SHA-256 of the raw body**; it does **not** keep the payload (large, and Paddle keeps the event: look it up by ID).
Nothing deletes it (GoBD): no retention rule covers the table.

What makes it append-only, and what does not:

1. **The interface.** `BillingLedger` has `append`, `entry` and `forSubscription`, no update and no delete; code that must
   not write it (the reconciler) is given only a `BillingLedgerReader`.
2. **The code path.** Only the `hooks` Function builds a ledger it can append to (`AppwriteBillingLedger` is exported for
   it through `package:api/billing_stores.dart`); `hooks` holds database scopes only, no user, team, file or messaging
   scope (`functions/hooks/test/scopes_test.dart`, `schema` test), so it is a different key from `api`'s.
3. **The unique key.** An append is an insert whose row ID derives from `ledgerKey` and which also hits the unique
   `ledgerKey` index: a second append of one key is a 409, which is how a replay is recognised.

**What the platform does NOT enforce:** a key with `documents.write` can also update and delete any row, and Appwrite
cannot scope a key to one table or to "create only". Both Functions' keys hold it, so a bug or a compromise in either
could edit or delete a ledger row; the guarantee is the code, not the platform. **Follow-ups (not done, listed for
the issue's acceptance):** (a) a tamper-evident hash chain over `billing_events` (each row carrying the hash of the
previous), checked by a scheduled job, so an edit is at least detected; (b) shipping every row to an external
write-once store (object storage with retention lock) as the audit copy; (c) a self-hosted Appwrite with a database
user that has `INSERT` and `SELECT` only on that table.

### Idempotency, ordering and what can still go wrong

`BillingEngine.process` appends each change's row **first** and applies its effect **only if the row was new**. So: a
replay (same event ID, Paddle redelivers on any non-2xx or a network blip) finds its rows and does nothing, and an event
whose append fails never touches an entitlement (`BillingEngine` test, with the order broken on purpose as the sabotage
proof). The entitlement update is a read then a write, ordered by the event's own `occurred_at`: an event older than the
state is recorded and **not** applied.

Honest limits: (1) a crash **between** the ledger append and the entitlement write leaves a row whose effect never
happened, and Paddle's redelivery is a replay that skips it; the reconciler repairs it from Paddle's data within an hour.
(2) TablesDB has no compare-and-set, so two *concurrent* events for one subscription can overwrite each other's
write; the same repair applies. (3) A multi-change event that crashes after `#1` is finished by the redelivery (it skips
`#1` and applies `#2`).

### The entitlement: a function of state and time

`billing_entitlements` holds one `SubscriptionState` per Paddle subscription (`serverOnly`; written by `hooks` and the
reconciler). **What the owner may do is computed on every read** (`SubscriptionState.entitlementAt(now, policy)`), never
stored: a past-due subscription has access for `BILLING_GRACE_DAYS` (default 7) after `pastDueSince`, then none, **with no
event in between**; a scheduled cancellation ends access at its `effective_at` the same way (grace is computed from
time, not written as an event). `Entitlement` carries plan, quantity, status
(`none`/`active`/`trialing`/`pastDue`/`expired`/`paused`/`canceled`), `hasAccess` (gate on this), `renewsAt`, `cancelsAt`
and `graceEndsAt`. An owner is a **user or a team**, team-first in the app: the active team if the user still belongs to
it, else the user (`BillingOwnerResolver` in the app). One owner may hold several subscriptions (an old ended one and a
current one); the reader prefers the one that grants access.

**Server-side gating.** Inside a Function or a scheduled job: `EntitlementReader(store: AppwriteEntitlementStore(client:
..., databaseId: ...), policy: ...).forOwner(owner)` and check `hasAccess`. A worker outside Appwrite (a separate
scanner service, say) calls the `billing` action's `entitlement_of` (the same allow-list as the `jobs` action, `JOBS_WORKER_USER_IDS`).
The app calls `entitlement`, which needs the caller to be the user or a member of the team.

### Operations and who may do them

The `billing` action (`requiresUser: true`; the caller is the router's `x-appwrite-user-id`): `start_checkout` (plan,
quantity), `open_portal`, `update_quantity` (prorated) and `entitlement`; `owner` is `user:<id>` or `team:<id>` (default:
the caller). **Manage** (checkout, portal, quantity) needs the user to be that user, or the team's owner or an admin;
**read** needs any member (`AppwriteBillingAccess`, from the team membership roles). A checkout is refused while the
owner already has a subscription that grants access. The action **never writes an entitlement or the ledger**: the
entitlement follows the webhook, so there is one path into it; `update_quantity` answers the entitlement Paddle's reply
implies, not stored. Failures are `{"error": {"code", "message"}}` with `forbidden` (403), `no_subscription` (404),
`invalid_request`/`unknown_plan` (400), `not_configured` (503), `provider_error` (502; the Paddle detail goes to the log).

### The reconciler

`BillingReconcilerJob` (hourly, wrapped in `OncePerSlotJob`) compares Paddle's view of each subscription (status,
quantity, plan) with the ledger and the entitlement: it lists Paddle's subscriptions (up to 10 pages of 200), and fetches
by ID the ones it knows and the listing missed (oldest comparison first, 100 per run). **It corrects the entitlement from
Paddle's data** (the correction is dated by Paddle's `updated_at` and never moves `eventAt` backwards, so a late webhook
older than it cannot revert it) and **reports every divergence** as one log line each plus a summary (the Function log
is the only report channel; a clone wires it to alerting): `missingEntitlement` (a missed `subscription.created`: the
entitlement is created from Paddle's data and the owner from `custom_data`), `statusDiffers`, `quantityDiffers`,
`planDiffers` (all corrected), and the report-only `notInLedger`, `ledgerBehind` (an event may just not have arrived yet)
and `unknownToProvider`. **It never touches the ledger**: it holds a `BillingLedgerReader`. A subscription whose
`custom_data` names no owner cannot be created from the listing and is skipped (it is a configuration error: the checkout
always sets it). Does nothing while `PADDLE_API_KEY` is unset.

### Configuration

Function variables. On `hooks`: `PADDLE_WEBHOOK_SECRET` (secret: the notification destination's secret key; **unset means
every webhook is refused with 500**), `PADDLE_PLANS`, `BILLING_GRACE_DAYS`, `PADDLE_SIGNATURE_TOLERANCE_SECONDS`. On `api`:
`PADDLE_API_KEY` (secret, `pdl_sdbx_...` or `pdl_live_...`), `PADDLE_PLANS` (JSON `{"pro": "pri_..."}`: plan key to price
ID, also read by `hooks` to name the plan a price is), `BILLING_GRACE_DAYS`. The template sets none of them (a secret in
`.env.local` would need new provisioning code for a service nobody has an account for yet); set them in the console, or a
clone adds them to the `FunctionSchema.variables` and the provisioner. In the Paddle dashboard: add a **notification
destination** whose URL is `https://<hooks function domain>/paddle` (add the domain to `hooks` in the console), subscribe
it to the `subscription.*` events and `transaction.completed`, copy its secret key into `PADDLE_WEBHOOK_SECRET`; create the
prices and put their IDs into `PADDLE_PLANS`; set the approved checkout domain and the default payment link. A webhook
is public and unauthenticated by design; a forged one costs one HMAC and is a 401 (no rate limit is wired; the
platform's own execution limits apply).

### Tests and the live check

Unit tests need no network: `core/contracts/billing` (engine, entitlement, reconciler, fake), `backend/paddle`
(signature against an independently computed HMAC, parser, the API client over a fake HTTP client, the service),
`functions/hooks` (a forged, tampered, stale, unsigned and replayed webhook; the raw body; a ledger failure) and
`functions/api` (`billing` action, rows, the reconciler job).

**Live check** (the reviewer runs it; it needs the dev project and **no Paddle account**), from
`backend/appwrite/adapters`, alone (suites that deploy Functions never run together):

```
fvm flutter test --tags integration --run-skipped test/integration/appwrite_billing_integration_test.dart
```

It provisions, sets `PADDLE_WEBHOOK_SECRET` (a known test value) and `PADDLE_PLANS` on `hooks`, deploys `hooks` and
`api`, signs payloads itself with Paddle's scheme and POSTs them to `/paddle` from a client with no session. It proves the
exact raw body (spacing, a unicode escape, a trailing newline) verifies, the ledger rows `<id>#1`/`#2` and the
entitlement row, the owner reading its entitlement through the `billing` action, a replay answering `replayed` with no
new row and the entitlement row's `$updatedAt` unchanged, a forged signature, a tampered body and a missing signature
answering 401 with nothing written, and a newer event moving the quantity. It removes its variables, rows and users
afterwards. The Paddle API calls (checkout, portal, quantity, the reconciler's fetch) are fake-HTTP unit tests only: a
sandbox account is needed to see them run for real.

**Unverified live (no credentials where this was written):** the Paddle API field names above against a real sandbox
account; a request through the Function's own domain; the `Query.notEqual`/`orderAsc` list in
`AppwriteEntitlementStore.dueForReconciliation` (the status and `reconciledAt` indexes are declared, as are the others the
queries use); that the cron tick reaches `BillingReconcilerJob`.

## Sites, production and promotion

Deployment is operator-run from a checkout and **never part of CI** (the
template's CI is verification only). A failed deploy is a new issue, not a red
check.

**Sites.** `templateSchema.sites` declares two Appwrite Sites, deployed as
prebuilt static uploads by `bin/deploy_site.dart <site-id>`
(`dart_appwrite` 29.0.0's `Sites` service: `create`, `get`, `createDeployment`,
`getDeployment`). The tool never builds; build first, from the repo root:

| site id | build command | uploaded directory |
| --- | --- | --- |
| `app` | `cd apps/app && fvm flutter build web --dart-define=BACKEND=appwrite --no-web-resources-cdn` | `apps/app/build/web` (SPA, fallback `index.html`) |
| `website` | `fvm dart run melos run website:build` | `apps/website/build/jaspr` |

A missing or empty build directory aborts with the command above. An absent
Site is created on the first deploy (framework `other`, `static` adapter, empty
install/build commands, `node-22` build runtime). **Unverified live** (no
credentials where this was written): that Appwrite accepts that create call and
serves the upload as-is, and the `ready` activation. Check with the dev project
once: `dart run bin/deploy_site.dart website --dry-run`, then without
`--dry-run`, then open the Site's URL.

**Production project.** A second, gitignored env file
`backend/appwrite/tool/.env.production.local` (same keys as `.env.local`, same
worktree-sharing lookup) configures production. Every command takes
`--production` to use it; **without that flag no command touches production**:
`BackendEnv.load` throws `ProductionNotConfirmedException` for the production
target unless explicitly allowed, production reads *only* its own file (a stray
dev `APPWRITE_*` variable cannot redirect it), and a dev run whose
`APPWRITE_PROJECT_ID` equals the production project's is refused too.

**Promotion.** `dart run bin/promote.dart --production --dry-run`, then without
`--dry-run`. It refuses unless HEAD is exactly at a tag and the tree is clean;
a real run also refuses unless the same commit had a successful dry run (a
marker under the system temp directory). Order: apply schema (`Provisioner`; the
dry run uses `DryRunAdmin`, which reads the real project and sends no writes),
deploy each Function, deploy each Site, stopping at the first failure. A Function
dry run only reports (it does not stage or build); a Site dry run checks the
build directory exists and whether the Site exists. See `docs/releasing.md`
"Deploying" for the whole procedure.

**Scoped API keys.** `templateSchema.apiKeys` declares three keys with exact
scopes: `provisioner`, `deployer` (`functions.*`, `sites.*`) and
`review-demo-seeder`. `BackendEnv.load(keyId: ...)` reads
`APPWRITE_API_KEY_<ID>` (`APPWRITE_API_KEY_DEPLOYER`, ...) and falls back to the
single `APPWRITE_API_KEY`, so an existing setup keeps working. **Limitation:**
`dart_appwrite` 29.0.0's project `Project` service can list, get, update and
delete keys but has **no `createKey`** (only `createEphemeralKey`; the
`createKey` methods in the SDK belong to the Apps and Organization services),
and appwrite-cli 27+ dropped `project create-key` (see step 3 above). So the
tool cannot provision keys: `dart run bin/api_keys.dart [--production]` prints
a per-key checklist (the `appwrite-cli@26.1.0` command that pipes the secret
straight into the env file) and `--audit` compares the declaration against the
project's real keys (scope drift, missing, undeclared). `--audit` needs a key
with `keys.read`, which no declared key has on purpose; use a short-lived one.

**Response headers on Sites (CSP, HSTS, Referrer-Policy): not settable through
the tool, live check outstanding.** In `dart_appwrite` 29.0.0 neither
`Sites.create` nor `Sites.update` has a headers parameter and the `Site` model
has no header field, so there is nothing to declare or deploy. A web search
turned up no Appwrite documentation for custom response headers on Sites
either. **For the reviewer:** open the deployed Site with `curl -sI <site-url>`
and the console's Site settings, record which of `Content-Security-Policy`,
`Strict-Transport-Security` and `Referrer-Policy` are present and whether the
console offers any header setting. Until that is known, CSP for the Flutter app
and the website would have to be a `<meta http-equiv>` tag (no `frame-ancestors`
or HSTS that way) or a custom domain behind a proxy that adds headers. Appwrite
Cloud itself serves HTTPS.

**Unique indexes.** `TableIndexSchema(unique: true)` (already supported and
provisioned, e.g. `profiles.userId_unique`) covers plain uniqueness.
"At most one *open* row per key" has no partial index in Appwrite, so use
`TableIndexSchema.oneOpenRowPerKey(openKeyColumn: 'openKey')`: an optional
column holding the key while the row is open and null once closed, with a unique
index over it (nulls do not collide). `schema/test/appwrite_schema_test.dart`
covers the declaration. **Unverified live:** that Appwrite's unique index
allows many null values (true for the MariaDB behind it, not confirmed here).

## How row isolation works

A table-level permission is a **blanket grant over every row**. Row security (`rowSecurity: true`) only
*adds* narrower per-row grants; it never withdraws a table-level one. So a signed-in table gets exactly one
table-level permission, `create(users)`, and every read, update and delete is allowed by the row's own
permissions alone (`AppwriteDocumentRepository.create` sets `read/update/delete(user:<id>)` on each row):
a user can get, update and delete exactly the rows naming them, and a list returns only those.
`publicRead` tables add `read(any)` on purpose, which makes **every row of that table public**.
`serverOnly` tables carry no table-level permission, so only the server key reaches them.

**Never grant read, update or delete at table level on a per-user or per-team table.** The per-`TableAccess`
lists are pinned by `tool/test/table_access_test.dart`. `bin/provision.dart` reconciles existing tables:
drift in a table's permissions or `rowSecurity` is an update (listed under `--dry-run`), so a project
provisioned before the row-security rule is repaired by the next `provision`. The live proof is the cross-user test in
`adapters/test/integration/` (`melos run test:integration:backend_appwrite`).

## Auth methods this project must run with disabled

**Account-takeover finding, live-verified:** Appwrite enables every auth
method by default on a new project. With `email-password` left on, *any*
client can call the public `Account.create(userId, email, password)`
endpoint for an arbitrary, unverified email. Combined with the
live-verified finding that `createEmailToken` looks a user up **by email**
and silently reuses whatever account already owns it (see
`AppwriteAuthService`'s "Email-code existence finding" dartdoc,
`backend/appwrite/adapters`), that's a real account takeover: an attacker
pre-creates `victim@x` with a password of their choosing, the victim later
signs up for real through this template's own email-OTP flow, and lands in
the *attacker's* pre-created account — the attacker, still holding the
password, can sign in as the victim at any time. An earlier version of
the App Review demo path (see below) used an email+password session
for one allow-listed account and was rejected for exactly this reason: the
hole is in leaving `email-password` enabled at all, regardless of which
account the demo path itself targets.

`Provisioner` (`lib/src/provisioner.dart`) closes this on every provisioning
run — `bin/provision.dart`, for the dev project and any real deployed
project alike — by disabling `email-password`, `magic-url`, `invites`,
`jwt`, `phone` and `anonymous` project-wide (`unusedAuthMethods`; the API
key needs `project.write` — see "Configuration" above). `anonymous` joined
this list when guest mode was removed from the template entirely.
`email-otp` (this template's one real sign-in flow) is the only method left
alone; OAuth providers aren't part of this at all, since each is off by
default until an app configures real provider credentials for it.

**Verified live** (2026-09-24): after `bin/provision.dart`,
`GET /project` reported
`email-password`/`magic-url`/`invites`/`jwt`/`phone`/`anonymous` all
`enabled: false` and `email-otp` still `true`; a raw `POST /account` with a
password, a raw `POST /account/sessions/email`, and a raw
`POST /account/sessions/anonymous` all returned `501
user_auth_method_unsupported`; a raw `POST /account/tokens/email` (OTP)
still returned `201`. A second `bin/provision.dart` run reported "Up to
date - nothing to do." See
`backend/appwrite/tool/test/integration/auth_methods_disabled_integration_test.dart` for
the same checks as an automated, repeatable test.

**If your project already had real users signed up via email/password
before adopting this policy:** those accounts keep existing and can still
be signed into by other means you provide (this template's own flows don't
use passwords at all, by design), but the public password sign-up/sign-in
endpoints stop working for anyone the moment `bin/provision.dart` runs. Plan
a migration (e.g. a forced password-reset-to-OTP flow) before running it
against a project with real password users, or drop `unusedAuthMethods`'
`email-password` entry in your own clone if you still need it — this
template ships the OTP-only default, not a mandate.

## App Review demo access

`bin/seed_review_demo_account.dart <email>` idempotently creates one real
Appwrite user with **no password** (the account-takeover finding above is
exactly why not — see `apps/app/README.md`'s "App Review demo access"
section for the full design) and configures the deployed
`api` Function's `REVIEW_DEMO_USER_ID`/`REVIEW_DEMO_CODE`
variables (read by its `review_demo_sign_in` action) to point at it. Rerunning it against an already-configured account
is a no-op. `--rotate` (`dart run bin/seed_review_demo_account.dart --rotate
<email>`) instead always generates a fresh code and replaces the old one in the
function and in `.env.local` — use it to rotate the code, or to repair a blank
*secret* `REVIEW_DEMO_CODE` variable on Appwrite Cloud (the API hides secret
values, so a blank one looks configured). The old code stops working, so update
the App Store Connect / Play Console review notes afterwards. The generated review code is never printed or passed as an
argument: it's appended to the shared, gitignored `backend/appwrite/tool/.env.local` (see
"The `.env.local` is shared across every worktree" above) as `REVIEW_DEMO_CODE`,
next to `APPWRITE_API_KEY` — read that file to get the value for the
store's review-notes field. Deploy the Function once (or after any change
to it) before seeding:

```
cd backend/appwrite/tool
dart run bin/deploy.dart api
dart run bin/seed_review_demo_account.dart reviewer@example.com
```

## Licences

`dart_appwrite` 29.0.0 — BSD-3-Clause (verified against the package's own
`LICENSE` file on GitHub, not just its pub.dev badge). `archive` — MIT.
`http` — BSD-3-Clause. All on the allow list
(`core/tooling/tooling/lib/src/licence_policy.dart`).
`mailer` 7.2.0 — MIT (pub.dev); its transitive packages `punycoder` and `unorm_dart` are MIT, `intl` and
`mime` BSD-3-Clause. `crypto` — BSD-3-Clause.
