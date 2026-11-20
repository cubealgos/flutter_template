/// What a ledger row records.
enum LedgerKind {
  /// A subscription's state as of an event.
  subscription,

  /// The change the provider has scheduled for a subscription (or none).
  scheduledChange,

  /// An event that has no effect on any entitlement (a payment, a customer, a
  /// subscription with no known owner): kept for the audit trail only.
  recorded;

  /// The kind named [name], or null.
  static LedgerKind? fromName(Object? name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }

    return null;
  }
}
