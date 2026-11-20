// Mapping a record onto table columns necessarily reads the record far more
// than the store's own members.
// ignore_for_file: solid_lints/feature_envy
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:mailing/mailing.dart';

/// The `mail_deliveries` table's ID.
const String mailDeliveriesTable = 'mail_deliveries';

/// The `mail_suppressions` table's ID.
const String mailSuppressionsTable = 'mail_suppressions';

/// The characters of a SHA-256 hex digest used as a row ID (Appwrite allows
/// 36 at most).
const int _rowIdLength = 32;

/// The [MailStore] over the `mail_deliveries` and `mail_suppressions` tables.
///
/// Both are unique, and the row ID is derived from the unique value too, so
/// claiming is *inserting the row* and a 409 means someone already did, atomic
/// twice over (the mechanism `job_claims` and `job_slots` use). The delivery
/// row stores a SHA-256 of the idempotency key, never the key (callers build
/// keys from user IDs and dates) and never an address.
class AppwriteMailStore implements MailStore {
  /// Creates a store over [client] for [databaseId].
  AppwriteMailStore({required Client client, required this.databaseId})
    : _tablesDb = TablesDB(client);

  /// The database holding the mail tables.
  final String databaseId;

  final TablesDB _tablesDb;

  /// The lowercase hex SHA-256 of [value].
  static String hashOf(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static String _deliveryRowId(String key) =>
      hashOf(key).substring(0, _rowIdLength);

  static String _suppressionRowId(String userId, String subscription) =>
      hashOf('$userId\n$subscription').substring(0, _rowIdLength);

  @override
  Future<bool> claim(MailDeliveryRecord record) async {
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: mailDeliveriesTable,
        rowId: _deliveryRowId(record.idempotencyKey),
        data: <String, dynamic>{
          'keyHash': hashOf(record.idempotencyKey),
          'userId': record.userId,
          'templateId': record.templateId,
          'locale': record.locale.tag,
          'status': record.status.name,
          'createdAt': record.createdAt.toUtc().toIso8601String(),
        },
      );

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) return false;
      rethrow;
    }
  }

  @override
  Future<MailDeliveryRecord?> find(String idempotencyKey) async {
    try {
      final row = await _tablesDb.getRow(
        databaseId: databaseId,
        tableId: mailDeliveriesTable,
        rowId: _deliveryRowId(idempotencyKey),
      );

      return _recordOf(idempotencyKey, row.data);
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> update(MailDeliveryRecord record) async {
    await _tablesDb.updateRow(
      databaseId: databaseId,
      tableId: mailDeliveriesTable,
      rowId: _deliveryRowId(record.idempotencyKey),
      data: <String, dynamic>{
        'status': record.status.name,
        'providerMessageId': record.providerMessageId,
        'detail': record.detail,
      },
    );
  }

  @override
  Future<void> release(String idempotencyKey) async {
    try {
      await _tablesDb.deleteRow(
        databaseId: databaseId,
        tableId: mailDeliveriesTable,
        rowId: _deliveryRowId(idempotencyKey),
      );
    } on AppwriteException catch (e) {
      if (e.code != HttpStatus.notFound) rethrow;
    }
  }

  @override
  Future<bool> isSuppressed(String userId, String subscription) async {
    for (final scope in <String>{subscription, allSubscriptions}) {
      try {
        await _tablesDb.getRow(
          databaseId: databaseId,
          tableId: mailSuppressionsTable,
          rowId: _suppressionRowId(userId, scope),
        );

        return true;
      } on AppwriteException catch (e) {
        if (e.code != HttpStatus.notFound) rethrow;
      }
    }

    return false;
  }

  @override
  Future<bool> suppress(
    String userId,
    String subscription,
    String reason,
  ) async {
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: mailSuppressionsTable,
        rowId: _suppressionRowId(userId, subscription),
        data: <String, dynamic>{
          'userId': userId,
          'subscription': subscription,
          'reason': reason,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return true;
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) return false;
      rethrow;
    }
  }

  static MailDeliveryRecord _recordOf(String key, Map<String, dynamic> data) =>
      MailDeliveryRecord(
        idempotencyKey: key,
        userId: data['userId'] as String,
        templateId: data['templateId'] as String,
        locale: MailLocale.parse(data['locale'] as String?),
        status: MailDeliveryStatus.values.firstWhere(
          (status) => status.name == data['status'],
          orElse: () => MailDeliveryStatus.failed,
        ),
        createdAt: DateTime.parse(data['createdAt'] as String),
        providerMessageId: data['providerMessageId'] as String?,
        detail: data['detail'] as String?,
      );
}
