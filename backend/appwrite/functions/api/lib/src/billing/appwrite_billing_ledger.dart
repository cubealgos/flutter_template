import 'dart:io';

import 'package:api/src/billing/billing_rows.dart';
import 'package:api/src/billing/billing_tables.dart';
import 'package:billing/billing.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The page size of a list call; Appwrite's own maximum.
const int _pageSize = 100;

/// The [BillingLedger] over the `billing_events` table (`serverOnly`).
///
/// **Append-only by construction here:** this class has no update and no
/// delete, only `createRow` and reads, and `append` is an insert whose
/// duplicate is refused (409) by the row ID derived from the unique key *and*
/// by the unique `ledgerKey` index. **What this cannot enforce:** the
/// Function's API key carries `documents.write` for every table, so any code
/// holding it could edit or delete a ledger row. Only `hooks` constructs this
/// class with a write path; every other reader gets a `BillingLedgerReader`.
/// See "Billing" in `backend/appwrite/README.md`.
class AppwriteBillingLedger implements BillingLedger {
  /// Creates a ledger over [client] for [databaseId].
  AppwriteBillingLedger({required Client client, required this.databaseId})
    : _tablesDb = TablesDB(client);

  /// The database holding `billing_events`.
  final String databaseId;

  final TablesDB _tablesDb;

  @override
  Future<bool> append(LedgerEntry entry) async {
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: billingEventsTable,
        rowId: ledgerRowId(entry.key),
        data: ledgerRowData(entry),
      );

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) return false;
      rethrow;
    }
  }

  @override
  Future<LedgerEntry?> entry(String key) async {
    try {
      final row = await _tablesDb.getRow(
        databaseId: databaseId,
        tableId: billingEventsTable,
        rowId: ledgerRowId(key),
      );

      return ledgerEntryFromRow(row.data);
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<LedgerEntry>> forSubscription(String subscriptionId) async {
    final entries = <LedgerEntry>[];
    String? after;
    while (true) {
      final page = await _tablesDb.listRows(
        databaseId: databaseId,
        tableId: billingEventsTable,
        queries: <String>[
          Query.equal('subscriptionId', <String>[subscriptionId]),
          Query.limit(_pageSize),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      for (final row in page.rows) {
        final entry = ledgerEntryFromRow(row.data);
        if (entry != null) entries.add(entry);
      }
      if (page.rows.length < _pageSize) break;
      after = page.rows.last.$id;
    }

    return entries..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }
}
