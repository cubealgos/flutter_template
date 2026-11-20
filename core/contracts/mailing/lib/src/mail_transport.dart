import 'package:mailing/src/mail_not_sent_exception.dart';
import 'package:mailing/src/mail_transport_result.dart';
import 'package:mailing/src/rendered_mail.dart';

/// Hands a rendered mail to a provider: Appwrite Messaging, SMTP, a recorder.
abstract interface class MailTransport {
  /// Sends [mail]. Returns the provider's verdict, throws
  /// [MailNotSentException] when nothing left.
  Future<MailTransportResult> send(RenderedMail mail);

  /// What the provider now says about [providerMessageId], or null when this
  /// transport can't tell (plain SMTP).
  Future<MailTransportResult?> refresh(String providerMessageId);
}
