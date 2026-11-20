import 'package:mailing/src/mail_delivery_status.dart';

/// What a send, or a later status read, reports.
class MailDeliveryResult {
  /// Creates a result.
  const MailDeliveryResult({
    required this.idempotencyKey,
    required this.status,
    this.providerMessageId,
    this.detail,
    this.replayed = false,
  });

  /// The send this is about.
  final String idempotencyKey;

  /// Where the mail got to.
  final MailDeliveryStatus status;

  /// True when this call did not send: a send with this key already existed
  /// and its stored result is returned.
  final bool replayed;

  /// The provider's ID for the mail (Appwrite's message ID), if it gave one.
  final String? providerMessageId;

  /// A human-readable reason for a refusal, failure, bounce or suppression.
  final String? detail;
}
