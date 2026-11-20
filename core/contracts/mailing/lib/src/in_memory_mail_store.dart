import 'package:mailing/src/mail_delivery_record.dart';
import 'package:mailing/src/mail_store.dart';

/// An in-memory [MailStore] for tests, atomic like the table: [claim] and
/// [suppress] reject a duplicate. Every method yields to the event loop first,
/// so two concurrent sends really interleave.
class InMemoryMailStore implements MailStore {
  final Map<String, MailDeliveryRecord> _records =
      <String, MailDeliveryRecord>{};
  final Map<String, String> _suppressions = <String, String>{};

  /// Every stored delivery record, for assertions.
  List<MailDeliveryRecord> get records => _records.values.toList();

  /// Every suppression as `userId|subscription` mapped to its reason.
  Map<String, String> get suppressions =>
      Map<String, String>.unmodifiable(_suppressions);

  @override
  Future<bool> claim(MailDeliveryRecord record) async {
    await Future<void>.delayed(Duration.zero);
    if (_records.containsKey(record.idempotencyKey)) return false;
    _records[record.idempotencyKey] = record;

    return true;
  }

  @override
  Future<MailDeliveryRecord?> find(String idempotencyKey) async {
    await Future<void>.delayed(Duration.zero);

    return _records[idempotencyKey];
  }

  @override
  Future<void> update(MailDeliveryRecord record) async {
    await Future<void>.delayed(Duration.zero);
    _records[record.idempotencyKey] = record;
  }

  @override
  Future<void> release(String idempotencyKey) async {
    await Future<void>.delayed(Duration.zero);
    _records.remove(idempotencyKey);
  }

  @override
  Future<bool> isSuppressed(String userId, String subscription) async {
    await Future<void>.delayed(Duration.zero);

    return _suppressions.containsKey('$userId|$subscription') ||
        _suppressions.containsKey('$userId|*');
  }

  @override
  Future<bool> suppress(
    String userId,
    String subscription,
    String reason,
  ) async {
    await Future<void>.delayed(Duration.zero);
    final key = '$userId|$subscription';
    if (_suppressions.containsKey(key)) return false;
    _suppressions[key] = reason;

    return true;
  }
}
