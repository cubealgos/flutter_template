import 'package:billing/src/billing_ledger_reader.dart';
import 'package:billing/src/ledger_entry.dart';

/// The append-only event ledger.
///
/// **Append-only here means the interface has no way to change a row**: only
/// [append] (create), and reads. A store must make [append] atomic on
/// [LedgerEntry.key] (on Appwrite: a unique index, the 409 mechanism). Whether
/// the *platform* also refuses an update or delete is a separate question that
/// depends on the backend; see "Billing" in `backend/appwrite/README.md` for
/// what Appwrite cannot enforce.
abstract interface class BillingLedger implements BillingLedgerReader {
  /// Writes [entry]. Returns false, and writes nothing, when a row with
  /// [LedgerEntry.key] already exists.
  Future<bool> append(LedgerEntry entry);

  /// The entry stored under [key], or null.
  Future<LedgerEntry?> entry(String key);
}
