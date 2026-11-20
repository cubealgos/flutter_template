import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';
import 'package:website/src/site_constants.dart';

/// The top navigation bar: brand mark, in-page section links, a language
/// switcher (EN/DE, preserving the current page), a primary CTA and (below
/// `1024px`, matching the reference site's own `.nav-links` breakpoint) a
/// hamburger toggle opening a full-viewport overlay carrying the same
/// section links plus the language switcher and CTA — below that
/// breakpoint the inline header only has room for the brand and the
/// toggle (the switcher, the CTA and the
/// toggle together no longer fit on one row at 390px), so both move into
/// the overlay instead of just disappearing. Ports the reference site's
/// `Nav.astro` (always-solid bar, brand + links + CTA + mobile overlay)
/// — square corners (no chamfer/clip-path button), the overlay itself
/// progressively enhanced by `web/motion.js`'s `initNavToggle`
/// (`aria-expanded`, Escape closes, closes on link click); with no JS the
/// toggle button is inert and the links/switcher stay reachable via the
/// footer's own "Company" column and language switcher instead (see
/// `SiteFooter`), so nothing is unreachable, just less convenient.
class SiteNav extends StatelessComponent {
  /// Creates the site navigation bar.
  const SiteNav({required this.locale, required this.slug, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  /// The current page's locale-agnostic slug, used to resolve the
  /// language switcher's target (the same page, other locale).
  final String slug;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);
    final home = locale.resolve('');
    final other = locale.other;
    // In-page anchors only make sense on the home page (the sections
    // they point to don't exist on legal pages) — resolved against home
    // regardless of the current route, so the nav works the same from
    // any page.
    final sectionBase = slug.isEmpty ? '' : home;

    return Component.fragment([
      header(classes: 'site-nav', [
        div(classes: 'site-nav__inner', [
          a(href: home, classes: 'site-nav__brand', const [
            Component.text(productName),
          ]),
          _links(strings, sectionBase),
          _actions(strings, home, other),
          _toggle(strings),
        ]),
      ]),
      _overlay(strings, sectionBase, home, other),
    ]);
  }

  Component _links(SiteStrings strings, String sectionBase) {
    return nav(
      classes: 'site-nav__links',
      attributes: {'aria-label': strings.navAriaLabel},
      [
        ul([
          for (final link in strings.navLinks)
            li([
              a(href: '$sectionBase${link.href}', [Component.text(link.label)]),
            ]),
        ]),
      ],
    );
  }

  Component _toggle(SiteStrings strings) {
    return button(
      const [
        span(
          classes: 'site-nav__toggle-icon site-nav__toggle-icon--menu',
          attributes: {'aria-hidden': 'true'},
          [Component.text('☰')],
        ),
        span(
          classes: 'site-nav__toggle-icon site-nav__toggle-icon--close',
          attributes: {'aria-hidden': 'true'},
          [Component.text('✕')],
        ),
      ],
      type: ButtonType.button,
      classes: 'site-nav__toggle',
      attributes: {
        'aria-expanded': 'false',
        'aria-controls': 'nav-overlay',
        'aria-label': strings.navMenuOpenLabel,
        // Read by `initNavToggle` to swap the accessible label between
        // open/close instead of hard-coding a second copy of it in JS.
        'data-open-label': strings.navMenuOpenLabel,
        'data-close-label': strings.navMenuCloseLabel,
      },
    );
  }

  // Below `1024px` the inline header only has room for the brand and the
  // toggle (see `.site-nav__actions`'s own `display: none` below that
  // breakpoint in `site.css` — the
  // language switcher and CTA together with the toggle no longer fit on
  // one line at 390px); the language switcher and CTA move in here
  // instead, so both stay reachable with one tap rather than only via
  // the footer's own switcher further down the page.
  Component _overlay(
    SiteStrings strings,
    String sectionBase,
    String home,
    SiteLocale other,
  ) {
    return div(
      id: 'nav-overlay',
      classes: 'nav-overlay',
      attributes: {
        'role': 'dialog',
        'aria-modal': 'true',
        'aria-label': strings.navAriaLabel,
      },
      [
        ul(classes: 'nav-overlay__links', [
          for (final link in strings.navLinks)
            li([
              a(href: '$sectionBase${link.href}', [Component.text(link.label)]),
            ]),
        ]),
        _overlayLang(strings, home, other),
        a(href: 'mailto:${strings.ctaEmail}', classes: 'nav-overlay__cta', [
          Component.text(strings.navCtaLabel),
        ]),
        button(
          const [
            span(attributes: {'aria-hidden': 'true'}, [Component.text('✕')]),
          ],
          type: ButtonType.button,
          classes: 'nav-overlay__close',
          attributes: {'aria-label': strings.navMenuCloseLabel},
        ),
      ],
    );
  }

  // Same rationale as `_actions`'s own `feature_envy` ignore: this
  // method's whole job is deriving hrefs/labels from `SiteLocale` for the
  // overlay's copy of the language switcher.
  // ignore: solid_lints/feature_envy
  Component _overlayLang(SiteStrings strings, String home, SiteLocale other) {
    return nav(
      classes: 'nav-overlay__lang',
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
        const Component.text(' · '),
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

  // Grouped so the language switcher sits with the CTA on the nav's
  // right side (not floating alone in the middle) and both wrap to a
  // second line together at narrow widths — see site.css's own comment
  // on `.site-nav__actions`.
  //
  // The language switcher's whole job is deriving hrefs/labels from
  // `SiteLocale` — moving that into `SiteLocale` itself would pull
  // presentation concerns (href shape, "which link is current") into a
  // small routing-only enum shared by every page, not just the nav.
  // ignore: solid_lints/feature_envy
  Component _actions(SiteStrings strings, String home, SiteLocale other) {
    return div(classes: 'site-nav__actions', [
      nav(
        classes: 'site-nav__lang',
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
          const Component.text(' · '),
          a(
            href: other.resolve(slug),
            attributes: {
              'hreflang': other.code,
              if (locale == SiteLocale.de) 'aria-current': 'true',
            },
            [Component.text(other.code.toUpperCase())],
          ),
        ],
      ),
      a(href: 'mailto:${strings.ctaEmail}', classes: 'site-nav__cta', [
        Component.text(strings.navCtaLabel),
      ]),
    ]);
  }
}
