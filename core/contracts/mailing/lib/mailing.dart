/// Backend-agnostic email: the `Mailer` interface, its models (`MailMessage`,
/// `MailDeliveryResult`), `MailerEngine` (the one implementation of the rules)
/// over a `MailStore` and a `MailTransport`, `MailCatalog` (de/en templates in
/// pure Dart), `UnsubscribeLinks` (signed one-click links) and in-memory fakes
/// for tests.
///
/// `backend/appwrite/functions/api` runs `MailerEngine` against Appwrite
/// tables, Appwrite Messaging and direct SMTP. Split into one file per
/// declared type under `src/` (matching this workspace's
/// `prefer_match_file_name` lint) - this file just re-exports them.
library;

export 'src/example_digest_template.dart';
export 'src/fake_mailer.dart';
export 'src/in_memory_mail_store.dart';
export 'src/invalid_unsubscribe_link_error.dart';
export 'src/invalid_unsubscribe_reason.dart';
export 'src/mail_catalog.dart';
export 'src/mail_delivery_record.dart';
export 'src/mail_delivery_result.dart';
export 'src/mail_delivery_status.dart';
export 'src/mail_invalid_error.dart';
export 'src/mail_locale.dart';
export 'src/mail_message.dart';
export 'src/mail_not_sent_exception.dart';
export 'src/mail_recipient.dart';
export 'src/mail_store.dart';
export 'src/mail_template.dart';
export 'src/mail_template_strings.dart';
export 'src/mail_transport.dart';
export 'src/mail_transport_result.dart';
export 'src/mailer.dart';
export 'src/mailer_engine.dart';
export 'src/recording_mail_transport.dart';
export 'src/rendered_mail.dart';
export 'src/unsubscribe_claim.dart';
export 'src/unsubscribe_links.dart';
