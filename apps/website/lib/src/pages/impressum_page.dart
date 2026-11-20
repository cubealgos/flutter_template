import 'package:jaspr/jaspr.dart';
import 'package:legal_facts/legal_facts.dart';
import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/pages/legal_page.dart';
import 'package:website/src/site_constants.dart';

// Long paragraph bodies are named constants here (rather than inline
// string literals inside the `sections:` list literals below) so a
// multi-line value never reads as "adjacent string literals inside a
// list" (solid_lints/no_adjacent_strings_in_list would otherwise flag it
// as an ambiguous missing comma) while staying a compile-time constant
// (interpolating LegalFacts' own const fields).
const String _vatSentenceEn =
    'VAT ID pursuant to Section 27a of the German VAT Act '
    '(Umsatzsteuergesetz): ${LegalFacts.vatId}';
const String _liabilitySentenceEn =
    'Template placeholder — replace with your own liability disclaimer '
    'for content and external links.';
const String _vatSentenceDe =
    'Umsatzsteuer-Identifikationsnummer gemäß § 27a Umsatzsteuergesetz: '
    '${LegalFacts.vatId}';
const String _liabilitySentenceDe =
    'Vorlagenplatzhalter — durch Ihren eigenen Haftungsausschluss für '
    'Inhalte und externe Links ersetzen.';

/// The Impressum (legal notice) page — structurally ports the reference site's
/// `impressum.astro` (address, represented-by, contact, register, VAT,
/// liability sections), filled with `LegalFacts`' placeholder
/// facts inside a template-text banner instead of reviewed legal copy.
class ImpressumPage extends StatelessComponent {
  /// Creates the Impressum page for [locale].
  const ImpressumPage({required this.locale, super.key});

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
      slug: 'impressum',
      title: 'Legal Notice (Impressum) — $productName',
      description: 'Legal notice for the operator of this site.',
      heading: 'Legal Notice (Impressum)',
      templateNoticeHeading:
          'Template text — replace with your lawyer-reviewed text',
      templateNoticeBody:
          'Every fact on this page is a placeholder from this template '
          "(the same ones apps/app/lib/app/config.dart's AppConfig "
          'ships), not real legal advice. Replace this whole page with '
          'your own, lawyer-reviewed Impressum before you ship.',
      sections: [
        LegalSection.address('Provider', [
          LegalFacts.companyName,
          LegalFacts.address,
        ]),
        LegalSection('Represented by', [
          '${LegalFacts.responsiblePerson} (Managing Director)',
        ]),
        LegalSection('Contact', ['Email: ${LegalFacts.contactEmail}']),
        LegalSection('Commercial register entry', [LegalFacts.register]),
        LegalSection('VAT identification number', [_vatSentenceEn]),
        LegalSection('Liability for content and links', [_liabilitySentenceEn]),
      ],
    );
  }

  LegalPage _de() {
    return const LegalPage(
      locale: SiteLocale.de,
      slug: 'impressum',
      title: 'Impressum — $productName',
      description: 'Impressum des Betreibers dieser Website.',
      heading: 'Impressum',
      templateNoticeHeading:
          'Vorlagentext — durch anwaltlich geprüften Text ersetzen',
      templateNoticeBody:
          'Jede Angabe auf dieser Seite ist ein Platzhalter dieser '
          "Vorlage (dieselben, die apps/app/lib/app/config.dart's "
          'AppConfig verwendet), keine echte Rechtsberatung. Ersetzen '
          'Sie diese gesamte Seite vor dem Livegang durch Ihr eigenes, '
          'anwaltlich geprüftes Impressum.',
      sections: [
        LegalSection.address('Anbieter', [
          LegalFacts.companyName,
          LegalFacts.address,
        ]),
        LegalSection('Vertreten durch', [
          '${LegalFacts.responsiblePerson} (Geschäftsführung)',
        ]),
        LegalSection('Kontakt', ['E-Mail: ${LegalFacts.contactEmail}']),
        LegalSection('Registereintrag', [LegalFacts.register]),
        LegalSection('Umsatzsteuer-Identifikationsnummer', [_vatSentenceDe]),
        LegalSection('Haftung für Inhalte und Links', [_liabilitySentenceDe]),
      ],
    );
  }
}
