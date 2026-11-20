import 'package:billing/src/ledger_kind.dart';

/// One row of the append-only ledger.
///
/// [key] is unique: the provider's event ID, or `<event id>#<n>` (n from 1)
/// when one event means several changes. The row holds what the event said
/// about the subscription, not the payload: a hash of the raw body ties it to
/// what the provider sent, which the provider keeps.
class LedgerEntry {
  /// Creates an entry.
  const LedgerEntry({
    required this.key,
    required this.eventId,
    required this.eventType,
    required this.kind,
    required this.occurredAt,
    required this.receivedAt,
    required this.bodyHash,
    this.subscriptionId,
    this.ownerKey,
    this.status,
    this.quantity,
    this.plan,
    this.detail,
  });

  /// The unique key: the event ID or `<event id>#<n>`.
  final String key;

  /// The provider's event ID.
  final String eventId;

  /// The provider's event type, as sent.
  final String eventType;

  /// What the row records.
  final LedgerKind kind;

  /// When the provider says it happened (UTC).
  final DateTime occurredAt;

  /// When this system recorded it (UTC).
  final DateTime receivedAt;

  /// SHA-256 (hex) of the exact raw request body.
  final String bodyHash;

  /// The subscription it concerns, if any.
  final String? subscriptionId;

  /// The owner it concerns (`BillingOwner.key`), if known.
  final String? ownerKey;

  /// For a subscription row: the provider status.
  final String? status;

  /// For a subscription row: the quantity.
  final int? quantity;

  /// For a subscription row: the plan key.
  final String? plan;

  /// A short free-text note (why an event was only recorded).
  final String? detail;
}
