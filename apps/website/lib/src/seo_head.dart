import 'package:jaspr/dom.dart';
// `package:jaspr/server.dart` (not `jaspr/jaspr.dart`) — it re-exports
// everything `jaspr.dart` provides except `Document`/`runApp`/
// `AppContext`, which it replaces with its own server-specific versions
// (see that library's own `export ... hide` line); importing both would
// make `Document` an ambiguous name (`jaspr.dart`'s conditional
// client/server export vs. `server.dart`'s explicit one).
import 'package:jaspr/server.dart';

import 'package:website/src/dom_extra.dart';
import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/site_constants.dart';

/// Per-page `<head>` metadata: title, description, canonical link, `en`/
/// `de` hreflang alternates, Open Graph/Twitter tags and (for the 404
/// pages) a `noindex` robots directive.
///
/// Renders via `Document.head`/`Document.html`, which Jaspr hoists into
/// the real document `<head>`/`<html>` at render time regardless of where
/// in the component tree they're mounted (see `HeadDocument`'s own
/// dartdoc) — every page mounts one of these directly in its `build()`,
/// no separate "layout" pass needed.
class SeoHead extends StatelessComponent {
  /// Creates a page's `<head>` metadata.
  const SeoHead({
    required this.locale,
    required this.title,
    required this.description,
    required this.slug,
    super.key,
    this.noIndex = false,
  });

  /// The page's own locale — sets `<html lang>` and which hreflang
  /// alternate is "self".
  final SiteLocale locale;

  /// Rendered verbatim in `<title>` and `og:title`/`twitter:title`.
  final String title;

  /// Rendered as the `<meta name="description">` and `og:description`/
  /// `twitter:description` content.
  final String description;

  /// The locale-agnostic route slug (`''` for the home page, otherwise no
  /// leading/trailing slash, e.g. `'impressum'`) — resolved per locale via
  /// `SiteLocale.resolve` for the canonical link and hreflang alternates.
  final String slug;

  /// `true` for a page with no real per-locale counterpart worth indexing
  /// (the 404 pages) — skips hreflang generation and adds
  /// `<meta name="robots" content="noindex, follow">`.
  final bool noIndex;

  @override
  Component build(BuildContext context) {
    final canonical = '$siteOrigin${locale.resolve(slug)}';
    const ogImage = '$siteOrigin/og-placeholder.svg';

    return Component.fragment([
      Document.html(attributes: {'lang': locale.code}),
      Document.head(
        title: title,
        children: [
          meta(name: 'description', content: description),
          if (noIndex)
            const meta(name: 'robots', content: 'noindex, follow')
          else ...[
            link(href: canonical, rel: 'canonical'),
            for (final alt in SiteLocale.values)
              link(
                href: '$siteOrigin${alt.resolve(slug)}',
                rel: 'alternate',
                attributes: {'hreflang': alt.code},
              ),
            link(
              href: canonical,
              rel: 'alternate',
              attributes: const {'hreflang': 'x-default'},
            ),
          ],
          const meta(attributes: {'property': 'og:type'}, content: 'website'),
          meta(attributes: const {'property': 'og:title'}, content: title),
          meta(
            attributes: const {'property': 'og:description'},
            content: description,
          ),
          meta(attributes: const {'property': 'og:url'}, content: canonical),
          const meta(attributes: {'property': 'og:image'}, content: ogImage),
          const meta(name: 'twitter:card', content: 'summary_large_image'),
          meta(name: 'twitter:title', content: title),
          meta(name: 'twitter:description', content: description),
          const meta(name: 'twitter:image', content: ogImage),
          const link(href: 'tokens.g.css', rel: 'stylesheet'),
          const link(href: 'site.css', rel: 'stylesheet'),
          const link(href: 'favicon.svg', rel: 'icon', type: 'image/svg+xml'),
          const script(src: 'motion.js', defer: true),
          // `[data-reveal]` content is hidden (opacity: 0) until
          // `web/motion.js` adds `.is-visible` on scroll — with no JS at
          // all, that class never gets added and the content would stay
          // permanently invisible. `<noscript>` only ever renders when
          // scripting is disabled, so this override can't fight the real
          // scroll-reveal transition on a normal visit.
          noscriptTag([
            styleTag(
              '[data-reveal]{opacity:1 !important;transform:none '
              '!important}.process-step::before{transform:scaleX(1) '
              '!important}',
            ),
          ]),
        ],
      ),
    ]);
  }
}
