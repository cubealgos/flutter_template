import 'dart:io';

import 'package:api/src/billing/billing_rows.dart';
import 'package:api/src/billing/billing_tables.dart';
import 'package:billing/billing.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The page size of a list call; Appwrite's own maximum.
const int _pageSize = 100;

/// The [EntitlementStore] over the `billing_entitlements` table
/// (`serverOnly`): one row per provider subscription, written only by server
/// code (the `hooks` webhook and the reconciler). A client reads an
/// entitlement through the `billing` action, never this table.
class AppwriteEntitlementStore implements EntitlementStore {
  /// Creates a store over [client] for [databaseId].
  AppwriteEntitlementStore({
    required Client client,
    required this.databaseId,
    DateTime Function()? clock,
  }) : _tablesDb = TablesDB(client),
       _clock = clock ?? (() => DateTime.now().toUtc());

  /// The database holding `billing_entitlements`.
  final String databaseId;

  final TablesDB _tablesDb;
  final DateTime Function() _clock;

  @override
  Future<SubscriptionState?> bySubscription(String subscriptionId) async {
    try {
      final row = await _tablesDb.getRow(
        databaseId: databaseId,
        tableId: billingEntitlementsTable,
        rowId: entitlementRowId(subscriptionId),
      );

      return stateFromRow(row.data);
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<SubscriptionState>> byOwner(String ownerKey) async {
    final page = await _tablesDb.listRows(
      databaseId: databaseId,
      tableId: billingEntitlementsTable,
      queries: <String>[
        Query.equal('ownerKey', <String>[ownerKey]),
        Query.limit(_pageSize),
      ],
    );

    return _states(page.rows.map((r) => r.data));
  }

  @override
  Future<void> put(SubscriptionState state) async {
    final data = stateRowData(state, _clock());
    final rowId = entitlementRowId(state.subscriptionId);
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: billingEntitlementsTable,
        rowId: rowId,
        data: data,
      );
    } on AppwriteException catch (e) {
      if (e.code != HttpStatus.conflict) rethrow;
      await _tablesDb.updateRow(
        databaseId: databaseId,
        tableId: billingEntitlementsTable,
        rowId: rowId,
        data: data,
      );
    }
  }

  @override
  Future<List<SubscriptionState>> dueForReconciliation(int limit) async {
    final page = await _tablesDb.listRows(
      databaseId: databaseId,
      tableId: billingEntitlementsTable,
      queries: <String>[
        Query.notEqual('status', <String>[ProviderStatus.canceled.wire]),
        Query.orderAsc('reconciledAt'),
        Query.limit(limit),
      ],
    );

    return _states(page.rows.map((r) => r.data));
  }

  List<SubscriptionState> _states(Iterable<Map<String, dynamic>> rows) => [
    for (final row in rows) ?stateFromRow(row),
  ];
}
