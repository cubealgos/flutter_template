# Changelog

All notable changes to `paddle_billing` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `paddle_billing-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Added

- Paddle Billing adapter: `PaddleSignature` (the `Paddle-Signature` header, `ts:<raw body>` HMAC-SHA256,
  constant-time compare, timestamp tolerance), `PaddleEventParser` (subscription events become a state change plus a
  scheduled-change change, every other event a `recorded` row), `PaddleApi` (checkout transaction, prorated quantity
  update, customer portal session, subscription get and list; sandbox or live from the key), `PaddleConfig`,
  `PaddlePlans`, `PaddleProviderSubscriptions` (the reconciler's view) and `BillingService` (the server-side
  operations, behind a `BillingAccess` check).
