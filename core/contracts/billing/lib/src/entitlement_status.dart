/// What an owner's entitlement is **right now** (see `Entitlement`).
enum EntitlementStatus {
  /// No subscription.
  none,

  /// Paid and current.
  active,

  /// In a trial.
  trialing,

  /// A payment failed; access continues until the grace period ends.
  pastDue,

  /// A payment failed and the grace period is over.
  expired,

  /// Paused.
  paused,

  /// Ended (canceled, or its scheduled cancellation has passed).
  canceled,
}
