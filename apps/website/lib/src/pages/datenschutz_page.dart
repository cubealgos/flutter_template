import 'package:jaspr/jaspr.dart';
import 'package:legal_facts/legal_facts.dart';
import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/pages/legal_page.dart';
import 'package:website/src/site_constants.dart';

// See impressum_page.dart's own comment on why these are named constants
// rather than inline multi-line string literals inside a `sections:` list
// literal (solid_lints/no_adjacent_strings_in_list).
const String _cookiesSentenceEn =
    'Template placeholder — describe here whether your site uses cookies '
    'or comparable storage, and for what purpose.';
const String _rightsSentenceEn =
    'Template placeholder — list the data-subject rights that apply '
    '(access, rectification, erasure, restriction, portability, '
    'objection) and how to exercise them.';
const String _cookiesSentenceDe =
    'Vorlagenplatzhalter — beschreiben Sie hier, ob und wofür Ihre '
    'Website Cookies oder vergleichbare Speichertechnologien verwendet.';
const String _rightsSentenceDe =
    'Vorlagenplatzhalter — listen Sie die geltenden Betroffenenrechte '
    '(Auskunft, Berichtigung, Löschung, Einschränkung, Übertragbarkeit, '
    'Widerspruch) und deren Ausübung auf.';

/// The Datenschutz (privacy notice) page — structurally ports the
/// reference site's `datenschutz.astro` (controller, cookies, rights, DPO,
/// supervisory authority sections), filled with `LegalFacts`'
/// placeholder facts inside a template-text banner instead of reviewed
/// legal copy.
class DatenschutzPage extends StatelessComponent {
  /// Creates the Datenschutz page for [locale].
  const DatenschutzPage({required this.locale, super.key});

  /// The page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    return switch (locale) {
      SiteLocale.en => _en(),
      SiteLocale.de => _de(),
    };
  }

  LegalPage _en() {
    return const LegalPage(
      locale: SiteLocale.en,
      slug: 'datenschutz',
      title: 'Privacy Notice — $productName',
      description: 'How this site processes personal data.',
      heading: 'Privacy Notice',
      templateNoticeHeading:
          'Template text — replace with your lawyer-reviewed text',
      templateNoticeBody:
          'Every fact on this page is a placeholder from this template '
          "(the same ones apps/app/lib/app/config.dart's AppConfig "
          'ships), not real legal advice. Replace this whole page with '
          'your own, lawyer-reviewed privacy notice before you ship.',
      sections: [
        LegalSection.address('1. Controller', [
          LegalFacts.companyName,
          LegalFacts.address,
        ]),
        LegalSection('2. Contact', ['Email: ${LegalFacts.contactEmail}']),
        LegalSection('3. Cookies', [_cookiesSentenceEn]),
        LegalSection('4. Your rights', [_rightsSentenceEn]),
        LegalSection('5. Supervisory authority', [
          LegalFacts.supervisoryAuthority,
        ]),
      ],
    );
  }

  LegalPage _de() {
    return const LegalPage(
      locale: SiteLocale.de,
      slug: 'datenschutz',
      title: 'Datenschutzerklärung — $productName',
      description: 'Wie diese Website personenbezogene Daten verarbeitet.',
      heading: 'Datenschutzerklärung',
      templateNoticeHeading:
          'Vorlagentext — durch anwaltlich geprüften Text ersetzen',
      templateNoticeBody:
          'Jede Angabe auf dieser Seite ist ein Platzhalter dieser '
          "Vorlage (dieselben, die apps/app/lib/app/config.dart's "
          'AppConfig verwendet), keine echte Rechtsberatung. Ersetzen '
          'Sie diese gesamte Seite vor dem Livegang durch Ihre eigene, '
          'anwaltlich geprüfte Datenschutzerklärung.',
      sections: [
        LegalSection.address('1. Verantwortlicher', [
          LegalFacts.companyName,
          LegalFacts.address,
        ]),
        LegalSection('2. Kontakt', ['E-Mail: ${LegalFacts.contactEmail}']),
        LegalSection('3. Cookies', [_cookiesSentenceDe]),
        LegalSection('4. Ihre Rechte', [_rightsSentenceDe]),
        LegalSection('5. Aufsichtsbehörde', [LegalFacts.supervisoryAuthority]),
      ],
    );
  }
}
