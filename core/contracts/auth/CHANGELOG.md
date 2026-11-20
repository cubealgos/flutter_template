# Changelog

All notable changes to `auth` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `auth-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Added

- Backend-agnostic authentication interfaces: `AuthService`, its typed `AuthError`
  hierarchy, `AuthCapabilities` (what a given backend actually supports),
  `AuthSession`, `EmailCodeRequest`, `LinkedIdentity` and `OAuthProvider`.
- `FakeAuthService`, an in-memory implementation for screens and tests — the default
  wiring for every `flutter test` run and a plain `flutter run`/`flutter build` with no
  `--dart-define`s.
- `backend/appwrite/adapters`'s `AppwriteAuthService` is the template's real
  implementation against this interface; a clone swaps in a different backend by
  implementing `AuthService` itself.
- `AuthOwnsTeamsError` (naming the teams), thrown by `AuthService.deleteAccount` when the user
  still owns a team; `FakeAuthService` mirrors the refusal through its optional
  `ownedTeamNames` and `onAccountDeleted` callbacks.
