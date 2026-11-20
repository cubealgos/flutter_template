import 'package:billing/src/ledger_entry.dart';

/// The read side of `BillingLedger`: what code that must never write the
/// ledger (the reconciler, a report) is given, so it cannot.
abstract interface class BillingLedgerReader {
  /// The entries of [subscriptionId], oldest first by `occurredAt`.
  Future<List<LedgerEntry>> forSubscription(String subscriptionId);
}
