import 'package:mailing/mailing.dart';

/// Picks the transport per mail: a mail with headers (every non-transactional
/// mail: `List-Unsubscribe`, `List-Unsubscribe-Post`) goes through [smtp],
/// because Appwrite Messaging cannot set headers; a mail without goes through
/// [messaging]. Either may be null when it is not configured, in which case a
/// mail that needs it is *not sent* (`MailNotSentException`, so a retry may
/// send once it is configured).
class RoutingMailTransport implements MailTransport {
  /// Creates the router.
  const RoutingMailTransport({this.messaging, this.smtp});

  /// Appwrite Messaging, or null.
  final MailTransport? messaging;

  /// Direct SMTP, or null.
  final MailTransport? smtp;

  @override
  Future<MailTransportResult> send(RenderedMail mail) async {
    final needsHeaders = mail.headers.isNotEmpty;
    final chosen = needsHeaders ? smtp : messaging;
    if (chosen == null) {
      throw MailNotSentException(
        needsHeaders
            ? 'This mail needs headers (List-Unsubscribe), which only direct '
                  'SMTP can set, and SMTP is not configured (MAIL_SMTP_*).'
            : 'Appwrite Messaging is not configured for transactional mail '
                  '(no SMTP provider; see "Email" in backend/appwrite/README.md).',
      );
    }

    return await chosen.send(mail);
  }

  @override
  Future<MailTransportResult?> refresh(String providerMessageId) async =>
      await messaging?.refresh(providerMessageId);
}
