/// The product rules an entitlement is computed with.
class EntitlementPolicy {
  /// Creates a policy.
  const EntitlementPolicy({this.grace = defaultGrace});

  /// Seven days: how long a past-due subscription keeps its access. A clone
  /// sets its own.
  static const Duration defaultGrace = Duration(days: 7);

  /// How long access continues after a payment first fails.
  final Duration grace;
}
