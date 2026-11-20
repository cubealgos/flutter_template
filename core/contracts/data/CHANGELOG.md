# Changelog

All notable changes to `data` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `data-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Changed

- `DocumentRepository.query` takes the scope as a second optional positional parameter (defaults to the
  caller's own rows, as before). `data` now depends on `teams` (for the fake's `TeamDirectory`).


### Added

- Optimistic concurrency: `Document.version` (an opaque write token) and
  `DocumentRepository.update(..., expectedVersion:)`, which refuses a stale update with the new
  `DataConflictError` instead of overwriting; the fake counts revisions. Without `expectedVersion`
  nothing changes (last write wins).
- `DocumentScope` (`UserScope`, `TeamScope(teamId, readRoles:, writeRoles:)`): `DocumentRepository.create`
  and `query` take a scope, so rows can belong to a team as well as a user.
- `FakeDocumentRepository(userId:, teams:)` and `.asUser`: mirrors Appwrite's user- and team-scoped row
  visibility (and "a creator can only grant roles they hold"), so a unit test catches a cross-tenant
  leak. Built with no `userId` it is the unchanged single-user fake.

- Backend-agnostic data interfaces: `DocumentRepository` (per-collection document CRUD,
  scoped to the current user), `StorageService` (per-user file upload/download/delete),
  `UserPreferences` (per-user key/value prefs), `VersionPolicy` (minimum-supported-
  version check), plus the `DataQuery`/`DataFilter` query shape and a typed `DataError`
  hierarchy.
- In-memory fakes of every interface (`FakeDocumentRepository`, `FakeStorageService`,
  `FakeUserPreferences`, `FakeVersionPolicy`) for screens and tests.
- `backend/appwrite/adapters` implements all four against Appwrite's `TablesDB`,
  `Storage` and `Account` services.
