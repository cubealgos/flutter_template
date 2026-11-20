import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';
import 'package:website/src/site_constants.dart';

/// The page footer: brand + tagline, a "Company" column (currently just a
/// link back to the landing page's features section), a "Legal" column
/// (Impressum/Datenschutz) a "Connect" column (a placeholder `mailto:`), a
/// bottom copyright row and its own language switcher. Ports the
/// reference site's `Footer.astro` column structure (incl. its bottom-row
/// language switcher, separate from the nav's own) with neutral
/// placeholder content and no chamfer/clip-path.
class SiteFooter extends StatelessComponent {
  /// Creates the site footer.
  const SiteFooter({required this.locale, required this.slug, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  /// The current page's locale-agnostic slug, used to resolve the
  /// language switcher's target (the same page, other locale).
  final String slug;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);
    final year = DateTime.now().year;
    final copyright = strings.footerCopyright.replaceFirst('{year}', '$year');

    return footer(classes: 'site-footer', [
      div(classes: 'site-footer__grid', [
        const div(classes: 'site-footer__brand', [
          p(classes: 'site-footer__product', [Component.text(productName)]),
          p(classes: 'site-footer__tagline', [Component.text(productTagline)]),
        ]),
        _companyColumn(strings),
        _legalColumn(strings),
        _connectColumn(strings),
      ]),
      div(classes: 'site-footer__bottom', [
        p(classes: 'site-footer__copyright', [Component.text(copyright)]),
        _langSwitcher(strings),
      ]),
    ]);
  }

  // The language switcher's whole job is deriving hrefs/labels from
  // `SiteLocale` — see `SiteNav._actions`'s own identical rationale for
  // why this isn't moved onto `SiteLocale` itself.
  // ignore: solid_lints/feature_envy
  Component _langSwitcher(SiteStrings strings) {
    final home = locale.resolve('');
    final other = locale.other;

    return nav(
      classes: 'site-footer__lang',
      attributes: {'aria-label': strings.languageSwitcherLabel},
      [
        a(
          href: home,
          attributes: {
            'hreflang': locale.code,
            if (locale == SiteLocale.en) 'aria-current': 'true',
          },
          [Component.text(locale.code.toUpperCase())],
        ),
        const span(
          attributes: {'aria-hidden': 'true'},
          [Component.text(' · ')],
        ),
        a(
          href: other.resolve(slug),
          attributes: {
            'hreflang': other.code,
            if (locale == SiteLocale.de) 'aria-current': 'true',
          },
          [Component.text(other.code.toUpperCase())],
        ),
      ],
    );
  }

  Component _companyColumn(SiteStrings strings) {
    return nav(
      classes: 'site-footer__column',
      attributes: {'aria-label': strings.footerCompanyHeading},
      [
        h2([Component.text(strings.footerCompanyHeading)]),
        ul([
          for (final link in strings.navLinks)
            li([
              a(href: '${locale.resolve('')}${link.href}', [
                Component.text(link.label),
              ]),
            ]),
        ]),
      ],
    );
  }

  Component _legalColumn(SiteStrings strings) {
    return nav(
      classes: 'site-footer__column',
      attributes: {'aria-label': strings.footerLegalHeading},
      [
        h2([Component.text(strings.footerLegalHeading)]),
        ul([
          li([
            a(href: locale.resolve('impressum'), [
              Component.text(strings.footerImpressumLabel),
            ]),
          ]),
          li([
            a(href: locale.resolve('datenschutz'), [
              Component.text(strings.footerDatenschutzLabel),
            ]),
          ]),
        ]),
      ],
    );
  }

  Component _connectColumn(SiteStrings strings) {
    return div(classes: 'site-footer__column', [
      h2([Component.text(strings.footerConnectHeading)]),
      ul([
        li([
          a(
            href: 'mailto:${strings.ctaEmail}',
            attributes: {
              'aria-label':
                  '${strings.footerEmailAccessiblePrefix} '
                  '${strings.ctaEmail}',
            },
            [Component.text(strings.ctaEmail)],
          ),
        ]),
      ]),
    ]);
  }
}
