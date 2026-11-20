/// How the provider's view and this system's differ.
enum DivergenceKind {
  /// The provider has a subscription this system has no entitlement for
  /// (a missed webhook). Corrected: the entitlement is created.
  missingEntitlement,

  /// The entitlement's status differs. Corrected.
  statusDiffers,

  /// The entitlement's quantity differs. Corrected.
  quantityDiffers,

  /// The entitlement's plan differs. Corrected.
  planDiffers,

  /// The ledger has no row for the subscription at all. Reported only: the
  /// ledger is never edited.
  notInLedger,

  /// The newest ledger row's status or quantity differs from the provider's.
  /// Reported only: an event may simply not have arrived yet.
  ledgerBehind,

  /// The entitlement exists but the provider has no such subscription.
  /// Reported only.
  unknownToProvider,
}
