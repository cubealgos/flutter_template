# Changelog

All notable changes to `billing` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `billing-vX.Y.Z`
(see `docs/releasing.md`).

## [Unreleased]

### Added

- Web billing contract: `Billing` (`startCheckout`, `openPortal`, `updateQuantity` (prorated),
  `entitlement`), `BillingOwner` (a user or a team), `Entitlement` (plan, quantity, status, renewal, grace) and
  `FakeBilling`.
- `SubscriptionState` and `EntitlementPolicy`: the entitlement is a function of the stored state and the current
  time, so the grace period is computed, never written as an event.
- `BillingLedger` (append-only: create only, no update or delete), `EntitlementStore`, `BillingEngine` (ledger row
  first, then the side effect; a replayed event id changes nothing; `#n` keys for an event with several changes; the
  `recorded` kind for events with no effect) and `BillingReconciler` (corrects the entitlement from the provider's
  data, reports every divergence, never touches the ledger).
