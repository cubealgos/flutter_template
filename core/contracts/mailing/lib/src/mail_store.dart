import 'package:mailing/src/mail_delivery_record.dart';

/// The persistence the engine rests on. TablesDB has no compare-and-set, so
/// the one atomic rule is [claim]: inserting a row unique on the idempotency
/// key, which a second insert loses with a 409 (the mechanism the jobs queue
/// and `OncePerSlotJob` use).
abstract interface class MailStore {
  /// Stores [record] if no record has its idempotency key; false when one
  /// exists (a retried send). Must be atomic.
  Future<bool> claim(MailDeliveryRecord record);

  /// The record for [idempotencyKey], or null.
  Future<MailDeliveryRecord?> find(String idempotencyKey);

  /// Replaces the stored record of [record]'s key.
  Future<void> update(MailDeliveryRecord record);

  /// Deletes the record of [idempotencyKey] so a retry may send: only for a
  /// send known not to have left.
  Future<void> release(String idempotencyKey);

  /// Whether [userId] must not get mail of [subscription]: unsubscribed from
  /// it, or suppressed for every subscription (a bounce).
  Future<bool> isSuppressed(String userId, String subscription);

  /// Suppresses [userId] for [subscription] (`*` for all), with [reason]
  /// (`unsubscribed` or `bounced`). Returns false when it already was.
  /// Must be atomic and idempotent.
  Future<bool> suppress(String userId, String subscription, String reason);
}

/// The subscription value meaning "every subscription".
const String allSubscriptions = '*';
