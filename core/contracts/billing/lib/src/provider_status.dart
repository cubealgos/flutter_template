/// A subscription's status as the provider reports it.
///
/// The values are Paddle's documented subscription statuses
/// (`active`, `canceled`, `past_due`, `paused`, `trialing`); another provider
/// maps its own onto them.
enum ProviderStatus {
  /// Billing normally.
  active('active'),

  /// In a trial.
  trialing('trialing'),

  /// A payment failed and has not been recovered yet.
  pastDue('past_due'),

  /// Paused.
  paused('paused'),

  /// Ended.
  canceled('canceled');

  const ProviderStatus(this.wire);

  /// The provider's own spelling.
  final String wire;

  /// The status spelled [wire], or null for anything else.
  static ProviderStatus? fromWire(Object? wire) {
    for (final status in values) {
      if (status.wire == wire) return status;
    }

    return null;
  }
}
