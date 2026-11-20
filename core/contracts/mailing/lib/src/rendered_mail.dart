import 'package:mailing/src/mail_locale.dart';
import 'package:mailing/src/mail_recipient.dart';

/// A mail ready for a transport: text filled in, footer and headers added.
class RenderedMail {
  /// Creates a rendered mail.
  const RenderedMail({
    required this.idempotencyKey,
    required this.recipient,
    required this.templateId,
    required this.locale,
    required this.subject,
    required this.text,
    this.html,
    this.subscription,
    this.headers = const <String, String>{},
  });

  /// The send's idempotency key.
  final String idempotencyKey;

  /// Who gets it.
  final MailRecipient recipient;

  /// The template it came from.
  final String templateId;

  /// The language it is written in.
  final MailLocale locale;

  /// The subject line (one line, no CR or LF).
  final String subject;

  /// The plain-text body.
  final String text;

  /// The HTML body, or null.
  final String? html;

  /// Every header to set, including `List-Unsubscribe` and
  /// `List-Unsubscribe-Post` for a non-transactional mail.
  final Map<String, String> headers;

  /// The subscription, null for a transactional mail.
  final String? subscription;
}
