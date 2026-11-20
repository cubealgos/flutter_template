# Changelog

All notable changes to `teams` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `teams-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Added

- Backend-agnostic team tenancy: `TeamService`, the `Team`/`Membership`/`Invitation`/
  `MembershipEvent` models, `TeamRoles` (`owner`, `admin`, `member` and the roles each implies),
  a sealed `TeamError` hierarchy, `TeamDirectory` (what a fake `DocumentRepository` asks to
  mirror team visibility).
- `TeamEngine`: the single implementation of the rules (exactly one owner, ownership transfer,
  invite/accept/expire/revoke, role changes, removal, the per-team history) over a `TeamStore`.
- `FakeTeamBackend`/`FakeTeamService`/`InMemoryTeamStore` for screens and tests.
- `Membership.membershipId`: the backend's own membership ID when it has one (Appwrite's), carried over the wire, so a live test can aim a raw Teams SDK call at the real membership.
- `TeamEngine.ownedTeams` (what account deletion refuses on) and `TeamEngine.redactEmailsOlderThan`,
  the retention hook that replaces old history email snapshots by `MembershipEvent.formerMember`
  (backed by `TeamStore.redactEventEmails`); `FakeTeamBackend.ownedTeamNames`/`forgetUser`.
