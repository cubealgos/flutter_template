import 'package:mailing/mailing.dart';

/// A transport that sends nothing and says so: the delivery record is real
/// (so idempotency, suppression and unsubscribe can be exercised end to end)
/// but no mail leaves. Selected by `MAIL_TRANSPORT=dry`; never the default.
class DryRunMailTransport implements MailTransport {
  /// Creates the transport.
  const DryRunMailTransport();

  @override
  Future<MailTransportResult> send(RenderedMail mail) async =>
      const MailTransportResult(
        status: MailDeliveryStatus.accepted,
        detail: 'dry run: nothing was sent (MAIL_TRANSPORT=dry)',
      );

  @override
  Future<MailTransportResult?> refresh(String providerMessageId) async => null;
}
