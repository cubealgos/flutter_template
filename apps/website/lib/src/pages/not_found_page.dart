import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';
import 'package:website/src/page_shell.dart';
import 'package:website/src/seo_head.dart';

/// The 404 page, one per locale (`/404.html`, `/de/404.html`) — unlike the
/// reference site's single locale-agnostic `dist/404.html` (a limitation of
/// Astro's special-cased 404 build, see that file's own comment), Jaspr's
/// static crawler renders each declared route independently, so each locale
/// gets its own single-language 404 instead of a bilingual one. `noIndex: true`
/// on the SEO head, matching the reference site's `skipHreflang` intent for
/// this one route.
class NotFoundPage extends StatelessComponent {
  /// Creates the 404 page for [locale].
  const NotFoundPage({required this.locale, super.key});

  /// The page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return Component.fragment([
      SeoHead(
        locale: locale,
        title: strings.notFoundTitle,
        description: strings.notFoundDescription,
        slug: '404.html',
        noIndex: true,
      ),
      PageShell(
        locale: locale,
        slug: '',
        content: [
          section(classes: 'not-found', [
            const p(
              classes: 'not-found__code',
              attributes: {'aria-hidden': 'true'},
              [Component.text('404')],
            ),
            h1([Component.text(strings.notFoundHeading)]),
            p([Component.text(strings.notFoundBody)]),
            a(href: locale.resolve(''), classes: 'not-found__link', [
              Component.text(strings.notFoundLinkLabel),
            ]),
          ]),
        ],
      ),
    ]);
  }
}
