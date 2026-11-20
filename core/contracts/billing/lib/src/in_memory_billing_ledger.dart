import 'package:billing/src/billing_ledger.dart';
import 'package:billing/src/ledger_entry.dart';

/// A `BillingLedger` in memory, for tests and `FakeBilling`.
class InMemoryBillingLedger implements BillingLedger {
  final Map<String, LedgerEntry> _rows = <String, LedgerEntry>{};

  /// Every entry, in the order written.
  List<LedgerEntry> get entries => List<LedgerEntry>.unmodifiable(_rows.values);

  @override
  Future<bool> append(LedgerEntry entry) async {
    if (_rows.containsKey(entry.key)) return false;
    _rows[entry.key] = entry;

    return true;
  }

  @override
  Future<LedgerEntry?> entry(String key) async => _rows[key];

  @override
  Future<List<LedgerEntry>> forSubscription(String subscriptionId) async {
    return _rows.values
        .where((e) => e.subscriptionId == subscriptionId)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }
}
