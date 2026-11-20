import 'package:billing/src/ledger_change.dart';

/// A verified, parsed provider event.
class ProviderEvent {
  /// Creates an event. [changes] is never empty: an event with no effect has
  /// one `LedgerChange.recorded`.
  ProviderEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.bodyHash,
    required List<LedgerChange> changes,
  }) : changes = List<LedgerChange>.unmodifiable(changes),
       assert(changes.isNotEmpty, 'an event has at least one change');

  /// The provider's event ID: the idempotency key.
  final String id;

  /// The provider's event type, as sent.
  final String type;

  /// When it happened (UTC).
  final DateTime occurredAt;

  /// SHA-256 (hex) of the exact raw body.
  final String bodyHash;

  /// What it means, in order.
  final List<LedgerChange> changes;
}
