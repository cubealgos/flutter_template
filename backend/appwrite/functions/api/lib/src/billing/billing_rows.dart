import 'dart:convert';

import 'package:billing/billing.dart';
import 'package:crypto/crypto.dart';

/// The longest row ID Appwrite accepts.
const int _maxRowIdLength = 36;

final RegExp _safeRowId = RegExp(r'^[A-Za-z0-9_]+$');

/// The row ID of a ledger row: derived from its unique key (an event ID may
/// carry a `#`, which a row ID cannot), so a second append of the same key
/// is refused by the row ID itself, **and** by the unique `ledgerKey` index.
String ledgerRowId(String ledgerKey) => 'e${_hashed(ledgerKey)}';

/// The row ID of an entitlement: the provider's subscription ID when it is a
/// valid row ID, else a hash of it.
String entitlementRowId(String subscriptionId) =>
    subscriptionId.length <= _maxRowIdLength &&
        _safeRowId.hasMatch(subscriptionId)
    ? subscriptionId
    : 's${_hashed(subscriptionId)}';

String _hashed(String value) => sha256
    .convert(utf8.encode(value))
    .toString()
    .substring(0, _maxRowIdLength - 1);

String _time(DateTime value) => value.toUtc().toIso8601String();

DateTime? _parse(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// The columns of a ledger row for [entry]; absent values are left out.
Map<String, dynamic> ledgerRowData(LedgerEntry entry) => <String, dynamic>{
  'ledgerKey': entry.key,
  'eventId': entry.eventId,
  'eventType': entry.eventType,
  'kind': entry.kind.name,
  'occurredAt': _time(entry.occurredAt),
  'receivedAt': _time(entry.receivedAt),
  'bodyHash': entry.bodyHash,
  'subscriptionId': ?entry.subscriptionId,
  'ownerKey': ?entry.ownerKey,
  'status': ?entry.status,
  'quantity': ?entry.quantity?.toString(),
  'plan': ?entry.plan,
  'detail': ?entry.detail,
};

/// The ledger entry a row holds, or null if it is not one.
LedgerEntry? ledgerEntryFromRow(Map<String, dynamic> row) {
  final kind = LedgerKind.fromName(row['kind']);
  final occurredAt = _parse(row['occurredAt']);
  final receivedAt = _parse(row['receivedAt']);
  final key = row['ledgerKey'];
  final eventId = row['eventId'];
  final eventType = row['eventType'];
  final bodyHash = row['bodyHash'];
  if (kind == null ||
      occurredAt == null ||
      receivedAt == null ||
      key is! String ||
      eventId is! String ||
      eventType is! String ||
      bodyHash is! String) {
    return null;
  }

  return LedgerEntry(
    key: key,
    eventId: eventId,
    eventType: eventType,
    kind: kind,
    occurredAt: occurredAt,
    receivedAt: receivedAt,
    bodyHash: bodyHash,
    subscriptionId: row['subscriptionId'] as String?,
    ownerKey: row['ownerKey'] as String?,
    status: row['status'] as String?,
    quantity: int.tryParse('${row['quantity'] ?? ''}'),
    plan: row['plan'] as String?,
    detail: row['detail'] as String?,
  );
}

/// The columns of an entitlement row for [state]. Every optional column is
/// written, null included, so a cleared value is cleared in the row too.
Map<String, dynamic> stateRowData(
  SubscriptionState state,
  DateTime now,
) => <String, dynamic>{
  'subscriptionId': state.subscriptionId,
  'customerId': state.customerId,
  'ownerKey': state.owner.key,
  'plan': state.plan,
  'quantity': '${state.quantity}',
  'status': state.status.wire,
  'currentPeriodEnd': state.currentPeriodEnd?.toUtc().toIso8601String(),
  'nextBilledAt': state.nextBilledAt?.toUtc().toIso8601String(),
  'canceledAt': state.canceledAt?.toUtc().toIso8601String(),
  'pastDueSince': state.pastDueSince?.toUtc().toIso8601String(),
  'scheduledAction': state.scheduledChange?.action.name,
  'scheduledAt': state.scheduledChange?.effectiveAt.toUtc().toIso8601String(),
  'eventAt': _time(state.eventAt),
  'source': state.source.name,
  'reconciledAt': _time(state.reconciledAt ?? now),
};

/// The state an entitlement row holds, or null if it is not one.
SubscriptionState? stateFromRow(Map<String, dynamic> row) {
  final owner = BillingOwner.tryParse(row['ownerKey']);
  final status = ProviderStatus.fromWire(row['status']);
  final eventAt = _parse(row['eventAt']);
  final id = row['subscriptionId'];
  final plan = row['plan'];
  final quantity = int.tryParse('${row['quantity']}');
  if (owner == null ||
      status == null ||
      eventAt == null ||
      id is! String ||
      plan is! String ||
      quantity == null) {
    return null;
  }
  final action = ScheduledAction.fromName(row['scheduledAction']);
  final at = _parse(row['scheduledAt']);

  return SubscriptionState(
    subscriptionId: id,
    customerId: row['customerId'] as String?,
    owner: owner,
    plan: plan,
    quantity: quantity,
    status: status,
    currentPeriodEnd: _parse(row['currentPeriodEnd']),
    nextBilledAt: _parse(row['nextBilledAt']),
    canceledAt: _parse(row['canceledAt']),
    pastDueSince: _parse(row['pastDueSince']),
    scheduledChange: action == null || at == null
        ? null
        : ScheduledChange(action: action, effectiveAt: at),
    eventAt: eventAt,
    source: row['source'] == StateSource.reconciler.name
        ? StateSource.reconciler
        : StateSource.webhook,
    reconciledAt: _parse(row['reconciledAt']),
  );
}
