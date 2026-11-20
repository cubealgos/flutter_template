# Changelog

All notable changes to `domain` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`domain-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- Pure-Dart domain models shared between `apps/app` and the Appwrite Functions under
  `backend/appwrite/functions/`: `AccountDeletionResult` and `UserProfile`.
- No Flutter dependency, deliberately — `backend/appwrite/tool/bin/deploy.dart` bundles
  this package as a vendored path dependency into every deployed Function, where only a
  plain Dart AOT runtime is available server-side.
- `environment: sdk:` pinned below the workspace's own `^3.13.0` (freezed 3.2.5's
  generated code for a `List`/`Map`/`Set` field needs a language version under 3.13).
