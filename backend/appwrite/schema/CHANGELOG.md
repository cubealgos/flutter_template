# Changelog

All notable changes to `appwrite_schema` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`appwrite_schema-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- Billing: the `serverOnly` tables `billing_events` (the append-only ledger, unique on `ledgerKey`, no
  payload) and `billing_entitlements` (one row per provider subscription), and the declared `hooks` Function (public,
  `execute: any`, database scopes only). Re-run `provision` on a clone to create them.
- Email: the `serverOnly` tables `mail_deliveries` (the idempotency record, unique on a hash of the
  key) and `mail_suppressions` (unsubscribes and bounces, unique per user and subscription), the `messages.*`
  scopes on `api`, the `providers.*` scopes on the `provisioner` key, and `mailSmtpProviderId`. Re-run
  `provision` on a clone to create them.
- Four `serverOnly` tables for background work: `jobs` and `job_claims` (the leased queue; a claim is a
  row unique on `jobId` + `attempt`), `job_slots` (one row per scheduled job and slot, unique) and
  `rate_limits` (one row per hit, keyed by a hash). Re-run `provision` on a clone to create them.

### Fixed

- **Security:** `TableSchema.publicRead`'s dartdoc now states it makes every row public; the signed-in
  tables' table-level grants are create-only, fixed in `appwrite_tool`. Re-run `provision` on every
  clone created before the fix.

### Changed

- The schema declares one Function, the `api` router (`execute: ['any']`, a five-minute cron tick,
  scopes the union of its actions'), instead of `delete_account` and `review_demo_sign_in`. New
  `FunctionSchema.schedule`, `maxFunctions` (2: the Appwrite Cloud Free plan limit), `allowedFunctionIds`
  (`api`, and `hooks` reserved for inbound webhooks) and `apiCronSchedule`; a schema test fails if a
  third Function is declared.

### Added

- `TableSchema.serverOnly` (no client permission at all), the `team_invitations`,
  `team_membership_events` (server-only) and `team_notes` (example team-scoped) tables, the `team_admin`
  action scopes on `api`, and `nativeOwnerRole`/`nativeTeamRole` (the contract's owner is never Appwrite's own
  `owner` role).

- `SiteSchema` and `AppwriteSchema.sites` (the `app` and `website` Sites), `ApiKeySchema` and
  `AppwriteSchema.apiKeys` (three scoped keys), `TableIndexSchema.oneOpenRowPerKey` for the
  "one open row per key" unique-index pattern, and the package's first tests.
- `at_key` index on `team_membership_events`, for the history retention job.

### Fixed

- `delete_account` and `review_demo_sign_in` declare the `dart-3.12` runtime instead of
  `dart-3.13`, which Appwrite Cloud does not offer.
- `environment: sdk:` lowered to `^3.12.0`: the package is bundled into Function builds, which
  run on `dart-3.12`.

### Added

- `TableSchema.seedRows` and `SeedRow`: rows provisioning creates when absent. `app_config` seeds its
  `default` row with `minSupportedVersion: '0.0.0'`.

- The template's declarative Appwrite backend schema: `AppwriteSchema`, `TableSchema`,
  `ColumnSchema`, `TableIndexSchema`, `BucketSchema`, `FunctionSchema`, `TableOwnership`
  and `OwnedFileRef` — const-constructor data only, zero dependencies on purpose.
- Shared by `appwrite_tool` (provisioning/deployment tooling) and
  `backend/appwrite/functions/delete_account` (reads `TableOwnership` to find which rows
  and files belong to the calling user) without the deployed function bundle also
  vendoring `appwrite_tool`'s own tooling-only dependencies.
