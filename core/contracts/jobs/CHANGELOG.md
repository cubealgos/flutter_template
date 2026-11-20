# Changelog

All notable changes to `jobs` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `jobs-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Added

- Backend-agnostic leased job queue: `JobQueue` (enqueue with a `JobPriority` band, claim with a
  lease, heartbeat, complete, fail, release, status), the `Job`/`JobClaim`/`JobLease` models, a sealed
  `JobError` (`JobNotFoundError`, `JobLeaseLostError`) and `JobWire`, the JSON both ends speak.
- `JobQueueEngine`: the one implementation of the rules over a `JobStore`. Without compare-and-set, a
  claim is a row unique on (job id, attempt), a job's status is derived from its claims, and a write from
  an attempt that is no longer the latest is rejected (`JobLeaseLostError`).
- `InMemoryJobStore`/`FakeJobQueue` for tests, enforcing the same unique claim key.
