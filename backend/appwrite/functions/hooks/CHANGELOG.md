# Changelog

All notable changes to `hooks` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`hooks-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- The `hooks` Function: the public, unauthenticated receiver of inbound webhooks, routed by path. The
  `/paddle` hook verifies `Paddle-Signature` over the exact raw request body (`req.bodyBinary`, not a re-serialised
  `bodyJson`), parses the event, writes the ledger row before any side effect through `BillingEngine`, and answers 200
  for a replay, 401 for a forged or stale signature and 500 (so Paddle retries) when a store fails.
