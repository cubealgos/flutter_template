import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/dom_extra.dart';
import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/page_shell.dart';
import 'package:website/src/seo_head.dart';

/// One heading + body group inside a legal page. Either [paragraphs]
/// (plain body text, one `<p>` each) or [addressLines] (rendered as an
/// `<address>` block, each entry on its own line) is used — a section
/// with an address has no other paragraphs.
///
// This file groups a legal page's whole content model (LegalSection) and
// its shared shell (LegalPage) together, so its name doesn't match this
// first declaration — same convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class LegalSection {
  /// Creates a plain text section.
  const LegalSection(this.heading, this.paragraphs) : addressLines = null;

  /// Creates an `<address>` section.
  const LegalSection.address(this.heading, this.addressLines)
    : paragraphs = const [];

  /// The section's `<h2>`.
  final String heading;

  /// The section's body paragraphs, if it is not an address section.
  final List<String> paragraphs;

  /// The section's address lines, if it is an address section.
  final List<String>? addressLines;
}

/// Shared shell for the Impressum and Datenschutz pages: SEO head, page
/// chrome, an `<h1>`, a clearly marked "this is template text" banner
/// (legal facts here are
/// `LegalFacts`' placeholders, not reviewed legal text — see
/// `package:legal_facts/legal_facts.dart`) and a list of
/// [LegalSection]s.
class LegalPage extends StatelessComponent {
  /// Creates a legal page.
  const LegalPage({
    required this.locale,
    required this.slug,
    required this.title,
    required this.description,
    required this.heading,
    required this.templateNoticeHeading,
    required this.templateNoticeBody,
    required this.sections,
    super.key,
  });

  /// The page's locale.
  final SiteLocale locale;

  /// The page's locale-agnostic slug (`'impressum'`/`'datenschutz'`).
  final String slug;

  /// `<title>`.
  final String title;

  /// Meta description.
  final String description;

  /// `<h1>`.
  final String heading;

  /// The template-text banner's own heading.
  final String templateNoticeHeading;

  /// The template-text banner's body copy.
  final String templateNoticeBody;

  /// The page's legal sections, in order.
  final List<LegalSection> sections;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      SeoHead(
        locale: locale,
        title: title,
        description: description,
        slug: slug,
      ),
      PageShell(
        locale: locale,
        slug: slug,
        content: [
          section(classes: 'legal-hero', [
            div(classes: 'legal-hero__inner', [
              h1([Component.text(heading)]),
            ]),
          ]),
          section(classes: 'legal-content', [
            div(classes: 'legal-content__inner', [
              div(classes: 'legal-template-notice', [
                p(classes: 'legal-template-notice__heading', [
                  Component.text(templateNoticeHeading),
                ]),
                p([Component.text(templateNoticeBody)]),
              ]),
              for (final s in sections) ...[
                h2([Component.text(s.heading)]),
                if (s.addressLines case final lines?) _addressBlock(lines),
                for (final para in s.paragraphs) p([Component.text(para)]),
              ],
            ]),
          ]),
        ],
      ),
    ]);
  }

  Component _addressBlock(List<String> lines) {
    final children = <Component>[];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) children.add(const br());
      children.add(Component.text(lines[i]));
    }

    return addressTag(children);
  }
}
