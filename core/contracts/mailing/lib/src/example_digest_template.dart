import 'package:mailing/src/mail_catalog.dart';
import 'package:mailing/src/mail_locale.dart';
import 'package:mailing/src/mail_template.dart';
import 'package:mailing/src/mail_template_strings.dart';

/// The `subscription` of [exampleDigestTemplate].
const String digestSubscription = 'digest';

/// The template's one example mail: a non-transactional digest, so
/// it carries the unsubscribe footer and the `List-Unsubscribe` headers. A
/// clone replaces it with its own templates (a transactional one has no
/// `subscription`).
const MailTemplate exampleDigestTemplate = MailTemplate(
  id: 'example_digest',
  subscription: digestSubscription,
  strings: <MailLocale, MailTemplateStrings>{
    MailLocale.en: MailTemplateStrings(
      subject: 'Your digest: {count} updates',
      text: 'Hello {name},\n\nthere are {count} updates for you.',
      html: '<p>Hello {name},</p><p>there are {count} updates for you.</p>',
    ),
    MailLocale.de: MailTemplateStrings(
      subject: 'Ihre Zusammenfassung: {count} Neuigkeiten',
      text: 'Hallo {name},\n\nes gibt {count} Neuigkeiten für Sie.',
      html: '<p>Hallo {name},</p><p>es gibt {count} Neuigkeiten für Sie.</p>',
    ),
  },
);

/// A catalog of just the example mail.
MailCatalog defaultMailCatalog() =>
    MailCatalog(const <MailTemplate>[exampleDigestTemplate]);
