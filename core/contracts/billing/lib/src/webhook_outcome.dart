import 'package:billing/src/webhook_status.dart';

/// The result of processing one provider event.
class WebhookOutcome {
  /// Creates an outcome.
  const WebhookOutcome({
    required this.status,
    required this.recorded,
    required this.applied,
    required this.skipped,
  });

  /// Whether the event was new.
  final WebhookStatus status;

  /// Ledger rows this call wrote.
  final int recorded;

  /// Rows whose effect changed an entitlement.
  final int applied;

  /// Rows that were recorded but changed nothing (an event older than the
  /// state it concerns, a change for an unknown subscription, a `recorded`
  /// row).
  final int skipped;
}
