import 'package:mailing/src/mail_locale.dart';
import 'package:mailing/src/mail_recipient.dart';

/// One mail to send: a template, its data, a locale and an idempotency key.
class MailMessage {
  /// Creates a message.
  const MailMessage({
    required this.idempotencyKey,
    required this.recipient,
    required this.templateId,
    this.locale = MailLocale.fallback,
    this.data = const <String, String>{},
    this.headers = const <String, String>{},
  });

  /// Names this send. **A retried send with the same key never mails twice**:
  /// the second call returns the first one's result with `replayed` set.
  /// Derive it from what the mail is about (`digest:<userId>:2026-W40`), never
  /// from the clock; at most 200 characters.
  final String idempotencyKey;

  /// Who gets the mail.
  final MailRecipient recipient;

  /// The `MailTemplate.id` to render.
  final String templateId;

  /// The language to render in; an unsupported one is a `MailLocale.parse`
  /// away from `MailLocale.fallback`.
  final MailLocale locale;

  /// The values of the template's `{placeholders}`; every one the template
  /// names must be present.
  final Map<String, String> data;

  /// Extra headers (`Reply-To`, `X-Entity-Ref-ID`). The engine adds
  /// `List-Unsubscribe` and `List-Unsubscribe-Post` itself for a
  /// non-transactional template and refuses to let a caller set them.
  final Map<String, String> headers;
}
