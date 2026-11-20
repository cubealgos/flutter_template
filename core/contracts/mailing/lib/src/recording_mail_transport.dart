import 'package:mailing/src/mail_delivery_status.dart';
import 'package:mailing/src/mail_not_sent_exception.dart';
import 'package:mailing/src/mail_transport.dart';
import 'package:mailing/src/mail_transport_result.dart';
import 'package:mailing/src/rendered_mail.dart';

/// A [MailTransport] that records what it was given instead of sending, for
/// tests and for `FakeMailer`.
class RecordingMailTransport implements MailTransport {
  /// Every mail handed to [send], in order.
  final List<RenderedMail> sent = <RenderedMail>[];

  /// What [send] answers; change it to simulate a rejection.
  MailTransportResult outcome = const MailTransportResult(
    status: MailDeliveryStatus.accepted,
    providerMessageId: 'recorded',
  );

  /// When set, [send] throws it (a [MailNotSentException] or any exception)
  /// instead of recording.
  Exception? failWith;

  /// What [refresh] answers; null means "can't tell".
  MailTransportResult? refreshed;

  @override
  Future<MailTransportResult> send(RenderedMail mail) async {
    await Future<void>.delayed(Duration.zero);
    final failure = failWith;
    if (failure != null) throw failure;
    sent.add(mail);

    return outcome;
  }

  @override
  Future<MailTransportResult?> refresh(String providerMessageId) async =>
      refreshed;
}
