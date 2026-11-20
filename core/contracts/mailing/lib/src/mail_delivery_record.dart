import 'package:mailing/src/mail_delivery_result.dart';
import 'package:mailing/src/mail_delivery_status.dart';
import 'package:mailing/src/mail_locale.dart';

/// The stored fact that a send was claimed and how it went: one per
/// idempotency key. It holds no address and no body.
class MailDeliveryRecord {
  /// Creates a record.
  const MailDeliveryRecord({
    required this.idempotencyKey,
    required this.userId,
    required this.templateId,
    required this.locale,
    required this.status,
    required this.createdAt,
    this.providerMessageId,
    this.detail,
  });

  /// The key the record is unique on.
  final String idempotencyKey;

  /// The recipient's user ID.
  final String userId;

  /// The template sent.
  final String templateId;

  /// The language sent in.
  final MailLocale locale;

  /// Where the mail got to.
  final MailDeliveryStatus status;

  /// When the send was claimed (UTC).
  final DateTime createdAt;

  /// The provider's message ID, once known.
  final String? providerMessageId;

  /// A reason, for a refusal, failure or bounce.
  final String? detail;

  /// The result this record reports; [replayed] marks a retried send.
  MailDeliveryResult toResult({bool replayed = false}) => MailDeliveryResult(
    idempotencyKey: idempotencyKey,
    status: status,
    replayed: replayed,
    providerMessageId: providerMessageId,
    detail: detail,
  );

  /// A copy with [status], [providerMessageId] and [detail] replaced.
  MailDeliveryRecord withOutcome({
    required MailDeliveryStatus status,
    String? providerMessageId,
    String? detail,
  }) => MailDeliveryRecord(
    idempotencyKey: idempotencyKey,
    userId: userId,
    templateId: templateId,
    locale: locale,
    status: status,
    createdAt: createdAt,
    providerMessageId: providerMessageId ?? this.providerMessageId,
    detail: detail,
  );
}
