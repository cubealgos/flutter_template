# Changelog

All notable changes to `appwrite_adapters` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`appwrite_adapters-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- `AppwriteBilling`, the `Billing` client of the `api` router's `billing` action: checkout, customer portal,
  prorated quantity update and the entitlement; a failure is a `BillingError` with the action's code.
- Live suite `appwrite_mail_integration_test.dart`: the retried send (one `mail_deliveries` row, `replayed`), the
  `mail_unsubscribe` action with no session, and the refusal of a tampered, wrong-secret and expired token, all with
  `MAIL_TRANSPORT=dry` (no SMTP needed); a real send skips itself unless SMTP is configured in `.env.local`; the test users are verified; the `/unsubscribe` route is
  proved through `createExecution` (HTML 400 page for a bad token, HTML confirmation for a good one, no write).
- `AppwriteJobQueue`, the `JobQueue` client of the `api` router's `jobs` action. The caller must be an
  allow-listed worker identity (no secret travels in the body).
- `AppwriteDocumentRepository.update(..., expectedVersion:)`: `Document.version` is the row's `$updatedAt`;
  a stale `expectedVersion` throws `DataConflictError` (read, compare, write: it narrows the race, it cannot
  close it, see the method's dartdoc). `mapAppwriteDataError` maps 409 to `DataConflictError`. New
  `requireVersion`.
- Live suite `appwrite_server_primitives_integration_test.dart`: the queue against the dev project (double claim,
  stale write, crash/lease expiry) and the stale update.

### Fixed

- The team-deletion live test's team cleanup is best effort, like the teams suite's: the harness key may lack `teams.write`.
- The team one-owner live test asserts the real refusals: `user_unauthorized` for a raw `updateMembership`, and
  `user_auth_method_unsupported` for a raw `createMembership`, since client invitations are disabled.
- **Security:** the integration suite now proves one signed-in user cannot get, list, update or delete
  another's row (in `profiles` and a second signed-in table), and that the provisioned table grants
  `create` only; `AppwriteDocumentRepository`'s dartdoc no longer says the table needs table-level
  read/update/delete. The fix itself is in `appwrite_tool`; clones must re-run `provision`.

### Changed

- `ApiClient`, the one small helper that executes a named action of the `api` router Function
  (`ApiClient.functionId` is the only Function id), replaces the two per-Function executions in
  `AppwriteAccountGateway`; `deleteAccount` and `signInWithReviewCode` behave as before.

### Changed

- `AppwriteVersionPolicy` reads the `app_config` row with a `listRows` ID query instead of `getRow`, so an
  absent row is an empty `200`, not a `404` the browser logs as a failed request; it now fails open on any
  error, including a malformed value, as its dartdoc always promised.
- `AppwriteAuthService.restoreSession` still asks `GET /account`; the 401 on a first load is documented as
  expected (the app logs nothing; only the browser's own "Failed to load resource" line remains).

- The integration test runs against an Appwrite Cloud dev project from `backend/appwrite/tool/.env.local`
  with the endpoint as configured, instead of rewriting it to the local stack's self-signed
  `https://localhost:8443`.

### Added

- `AppwriteTeamService` (calls the `team_admin` action of `api` through `ApiClient` for every `TeamService` operation),
  `TeamFunctionGateway`/`AppwriteTeamFunctionGateway`, and unit tests; an integration test
  (`test/integration/appwrite_teams_integration_test.dart`) proving team A can't read, list or write team
  B's rows, role-scoped rows hide from members, and the one-owner invariant holds even against the Teams
  SDK.
- `AppwriteDocumentRepository` creates and queries `TeamScope` rows (`Role.team(teamId[, role])`
  permissions, `teamColumn`), via `appwritePermissionsFor`; a 401 on creating a team row is a
  `DataPermissionError`.

- Appwrite adapters for `core/contracts/auth` and `core/contracts/data`:
  `AppwriteAuthService`, `AppwriteDocumentRepository`, `AppwriteStorageService`,
  `AppwriteUserPreferences` and `AppwriteVersionPolicy`, backed by the `appwrite` client
  SDK. This template's default backend wiring.
- `AccountGateway` and its default `AppwriteAccountGateway`, exported so an app (or a
  test) can build an `AppwriteAuthService.withGateway` against its own fake.
- Every adapter takes its Appwrite `Client` via constructor; DI wiring happens in the app
  (`get_it`), not here.
- The "email-code existence" finding documented on `AppwriteAuthService`: Appwrite's
  `createEmailToken` looks a user up by email and silently reuses whatever account
  already owns it — load-bearing context for the App Review demo sign-in design (see
  `apps/app/README.md`).
- `deleteAccount` maps the `owns_teams` refusal to `AuthOwnsTeamsError`; a live test covers it.
