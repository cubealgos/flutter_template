# Changelog

All notable changes to `appwrite_tool` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`appwrite_tool-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- `promote` deploys the `hooks` Function after `api`; its test expects it in the order.
- Email provisioning: from the `MAIL_*` variables of `.env.local` (`MailSettings`, `BackendEnv.mail`) `provision`
  creates the Appwrite Messaging SMTP provider `mail-smtp` and the `api` Function's `MAIL_*` variables (password and
  `MAIL_LINK_SECRET` as secret variables), each only when absent and never printing a credential; without
  `MAIL_SMTP_HOST` and `MAIL_FROM` it skips mail and says so (`ProvisionReport.notes`). `AppwriteAdmin` gains
  `messagingProviderExists`/`createSmtpProvider` and `createFunctionVariable(secret:)`. The `provisioner` key needs
  `providers.read`/`providers.write`.

### Fixed

- The `invites` auth method stays disabled and is pinned by a test: with it off, Appwrite refuses every client-side
  team invitation up front, so team roles change only through the `team_admin` action.
- **Security:** every signed-in table was provisioned with table-level `read`, `update` and `delete` for
  `users`, a blanket grant that let any signed-in user read, change and delete every other user's rows
  (and made per-team row permissions meaningless). Tables now get table-level `create(users)` only (plus
  `read(any)` for `publicRead`, none for `serverOnly`), with `rowSecurity` on. **Every clone created
  before this fix must pull it and re-run `provision`**: `Provisioner` now reconciles an existing
  table's permissions and `rowSecurity` (an update, listed under `--dry-run`), so the next run repairs the
  project. `AppwriteAdmin` gains `tableSettings` and `updateTableAccess`; `TableAccess` pins the lists.

### Changed

- `Provisioner` reconciles Functions: one the project has but the schema does not declare is deleted,
  first in the run and so first under `--dry-run`; a declared Function is never deleted. It frees the
  Free plan's 2 slots for the `api` router. `AppwriteAdmin` gains `listFunctionIds` and
  `deleteFunction`; a Function's cron `schedule` is provisioned and counts as drift.
- The review demo account's variables are set on the `api` Function (`reviewDemoFunctionId`); after the
  old Functions are deleted, rerun `bin/seed_review_demo_account.dart`.

### Added

- `TableSchema.serverOnly` tables map to `TableAccess.serverOnly` (`tableAccessOf`): created with no client
  permission and reconciled to an empty list by `updateTableAccess`, which now takes a `TableAccess`.

- Deployment path: `bin/deploy_site.dart` deploys the `apps/app` and `apps/website` web builds
  to Appwrite Sites; `bin/promote.dart --production` applies the schema and deploys Functions and
  Sites from a clean release tag, dry run first (a real run needs a dry run of the same commit);
  `--dry-run` on `provision.dart` (`DryRunAdmin`).
- A production project beside dev: `.env.production.local` (gitignored), selected only by
  `--production`; `BackendEnv.load` refuses production without `allowProduction` and refuses a dev
  config that points at the production project.
- Scoped API keys: `BackendEnv.load(keyId:)` reads `APPWRITE_API_KEY_<ID>` with `APPWRITE_API_KEY` as
  fallback; `bin/api_keys.dart` prints the creation checklist and `--audit`s declared against real
  keys (the SDK cannot create project keys).
- `runReportingFailures`: every deploy-side `bin/` command turns an `AppwriteException` (with the missing
  scopes and a pointer to `bin/api_keys.dart` for a `general_unauthorized_scope` 401) or one of its own
  refusals into one stderr line and a non-zero exit, never a stack trace.

### Removed

- The local Appwrite Docker stack (`backend/appwrite/docker/`) and everything that existed only
  to run it: `bin/backend_up.dart`, `bin/backend_down.dart`, `bin/bootstrap_local.dart`,
  `bin/local_env.dart` and their compose/process-runner/legacy-secrets-migration support.
  Appwrite Cloud is the dev backend.
- `buildClient` no longer accepts self-signed certificates; Cloud has real TLS.

### Changed

- `Provisioner` creates missing `seedRows` (create if absent, never overwrite an existing row), via new
  `AppwriteAdmin.rowExists`/`createRow`.

- The shared `.env.local` lookup stays (so every worktree finds one Cloud project's config); its
  docs and `.env.example` now describe an Appwrite Cloud project.

### Fixed

- `seed_review_demo_account` treats a blank (empty or whitespace-only) `REVIEW_DEMO_CODE` function
  variable as unconfigured and writes a code into it, instead of reporting "already configured".
  `deploy` leaves the variable blank on a fresh project, so the documented App Review demo path
  never worked on first use. A real existing value is still never overwritten or printed.
  `ReviewDemoAccountGateway.functionVariableExists` is now `functionVariableHasValue`.
  Appwrite Cloud hides a secret variable's value, so a blank *secret* variable can't be detected
  and counts as set; only non-secret variables are checked for blankness.
- `seed_review_demo_account.dart --rotate` always generates a fresh `REVIEW_DEMO_CODE`, upserts the
  function variable and replaces the `.env.local` line in place (the way to replace a blank secret
  variable on Cloud), then warns that the review notes must be updated. Without it, a blank
  `REVIEW_DEMO_CODE=` line in `.env.local` is now filled rather than skipped; a non-blank one is
  never overwritten.
- Tests model the template's functions on the `dart-3.12` runtime, the newest Dart runtime
  Appwrite Cloud offers.

### Fixed

- `BackendEnv.load` takes an optional `workingDirectory`. Its test no longer sets the
  process-wide current directory, which raced with other test files loading in parallel and
  failed `bundle_stager_test` intermittently.

### Added

- Provisioning and deployment tooling for the template's self-hosted Appwrite backend,
  each exposed as a `bin/` entrypoint:
  - `provision` — idempotent schema provisioning from `appwrite_schema`; also disables
    every auth method the template doesn't use (`email-password`, `magic-url`,
    `invites`, `jwt`, `phone`, `anonymous`) project-wide, on every run, local or real.
  - `deploy` — vendors a Function's dependencies (including `packages/domain` as a path
    dependency) and deploys it.
  - `local_env` — generates a gitignored local dev `.env`.
  - `backend_up` / `backend_down` / `bootstrap_local` — drive the pinned local Appwrite
    Docker stack (`backend/appwrite/docker/`).
  - `seed_review_demo_account` — seeds the one allow-listed App Review demo account.
