import 'package:jaspr/server.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/pages/datenschutz_page.dart';
import 'package:website/src/pages/home_page.dart';
import 'package:website/src/pages/impressum_page.dart';
import 'package:website/src/pages/not_found_page.dart';

/// This site's full static route table, as (request path, page builder)
/// pairs — request path first, in registration order.
///
/// **Not** `package:jaspr_router`: that package's every published version
/// (checked 0.8.1 through 0.9.0) calls `AppBinding.basePath`, a getter
/// jaspr only gained in 0.23.2 — one patch *after* the exact 0.23.1 this
/// workspace is pinned to (see pubspec.yaml's own comment on why). A
/// plain `switch` on the request path is all a small, fully static site
/// needs anyway: no client-side navigation, path parameters or nested
/// shells, just "which page for which URL".
const Map<String, SiteLocale> _en = {
  '/': SiteLocale.en,
  '/impressum': SiteLocale.en,
  '/datenschutz': SiteLocale.en,
  '/404.html': SiteLocale.en,
};

const Map<String, SiteLocale> _de = {
  '/de': SiteLocale.de,
  '/de/impressum': SiteLocale.de,
  '/de/datenschutz': SiteLocale.de,
  '/de/404.html': SiteLocale.de,
};

/// Every route this site serves, request path first.
final Map<String, SiteLocale> routeLocales = {..._en, ..._de};

Component _buildPage(String path, SiteLocale locale) {
  if (path.endsWith('/impressum')) return ImpressumPage(locale: locale);
  if (path.endsWith('/datenschutz')) return DatenschutzPage(locale: locale);
  if (path.endsWith('/404.html')) return NotFoundPage(locale: locale);

  return HomePage(locale: locale);
}

/// The app's root component: reports every static route to the `jaspr
/// build` crawler (see [AppState.preloadState]), then renders whichever
/// page matches the current request's path.
class App extends StatefulComponent {
  /// Creates the app's root component.
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

/// [App]'s state — only exists to run [preloadState] once per request,
/// server-side, before the first build (see `PreloadStateMixin`'s own
/// dartdoc).
class AppState extends State<App> with PreloadStateMixin {
  @override
  Future<void> preloadState() async {
    for (final path in routeLocales.keys) {
      await ServerApp.requestRouteGeneration(path);
    }
  }

  @override
  Component build(BuildContext context) {
    final path = context.url;
    final locale = routeLocales[path] ?? SiteLocale.en;

    return _buildPage(path, locale);
  }
}
