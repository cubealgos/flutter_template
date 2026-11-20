/// The two locales this site ships: English (default, unprefixed at `/`)
/// and German (prefixed at `/de`) — mirrors the reference Astro site's own
/// routing convention (native i18n, no bolted-on library) and the
/// workspace's standing en/de l10n rule.
enum SiteLocale {
  /// English — the default locale, served unprefixed at `/`.
  en('en', ''),

  /// German — served under the `/de` prefix.
  de('de', '/de');

  SiteLocale(this.code, this.pathPrefix);

  /// The `lang` attribute value / hreflang code.
  final String code;

  /// The route-path prefix for this locale (`''` for the default English
  /// routes, `/de` for German).
  final String pathPrefix;

  /// Resolves a locale-agnostic [slug] (`''` for the home page, no leading
  /// or trailing slash otherwise, e.g. `'impressum'`) to this locale's
  /// full route path, e.g. `resolve('impressum')` → `/de/impressum` for
  /// [de] and `/impressum` for [en].
  String resolve(String slug) {
    if (slug.isEmpty) return pathPrefix.isEmpty ? '/' : pathPrefix;

    return '$pathPrefix/$slug';
  }

  /// The other locale — used by the language switcher.
  SiteLocale get other => this == SiteLocale.en ? SiteLocale.de : SiteLocale.en;
}
