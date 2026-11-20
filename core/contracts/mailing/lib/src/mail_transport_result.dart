import 'package:mailing/src/mail_delivery_status.dart';

/// What a transport reports for one mail.
class MailTransportResult {
  /// Creates a result.
  const MailTransportResult({
    required this.status,
    this.providerMessageId,
    this.detail,
  });

  /// [MailDeliveryStatus.accepted], `delivered` or `rejected`.
  final MailDeliveryStatus status;

  /// The provider's ID for the mail, if it has one.
  final String? providerMessageId;

  /// A reason, for a refusal.
  final String? detail;
}
