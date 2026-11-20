import 'package:jaspr/server.dart' show Jaspr;
import 'package:jaspr_test/server_test.dart';
import 'package:website/app.dart';

/// Structural/accessibility/SEO checks that apply across every route —
/// one `h1`, a `lang` attribute, a skip link, `hreflang` alternates, and
/// no chamfer/clip-path anywhere in the rendered output (the
/// "square corners" requirement).
const _httpOk = 200;

void main() {
  // `ServerTester` never calls `main.server.dart`'s own
  // `Jaspr.initializeApp`, so its default `allowedPathSuffixes` (`[]`, not
  // the `['html', 'htm', 'xml']` `initializeApp`'s own default parameter
  // would otherwise supply) refuses any `.html`-suffixed request path —
  // including `/404.html` — with a bare, unrendered `404` before it ever
  // reaches `App`. Matches the real `main.server.dart` entrypoint's own
  // call exactly, just made explicit here since tests don't run through
  // it.
  Jaspr.initializeApp();

  final allPaths = [
    '/',
    '/impressum',
    '/datenschutz',
    '/404.html',
    '/de',
    '/de/impressum',
    '/de/datenschutz',
    '/de/404.html',
  ];
  final localeByPath = {
    for (final path in allPaths) path: path.startsWith('/de') ? 'de' : 'en',
  };

  for (final path in allPaths) {
    testServer('$path renders exactly one <h1>, the correct lang, a skip '
        'link, and no clip-path/chamfer', (tester) async {
      tester.pumpComponent(const App());
      final response = await tester.request(path);

      expect(response.statusCode, _httpOk);
      final body = response.body;

      expect(
        RegExp('<h1[ >]').allMatches(body).length,
        1,
        reason: '$path should render exactly one <h1>',
      );
      expect(body, contains('lang="${localeByPath[path]}"'));
      expect(body, contains('class="skip-link"'));
      expect(body, isNot(contains('clip-path')));
      expect(body, isNot(contains('chamfer')));
    });
  }

  final indexablePaths = [
    '/',
    '/impressum',
    '/datenschutz',
    '/de',
    '/de/impressum',
    '/de/datenschutz',
  ];

  for (final path in indexablePaths) {
    testServer('$path declares en/de hreflang alternates', (tester) async {
      tester.pumpComponent(const App());
      final response = await tester.request(path);
      final body = response.body;

      expect(body, contains('hreflang="en"'));
      expect(body, contains('hreflang="de"'));
      expect(body, contains('hreflang="x-default"'));
    });
  }

  for (final path in ['/404.html', '/de/404.html']) {
    testServer('$path is marked noindex and skips hreflang', (tester) async {
      tester.pumpComponent(const App());
      final response = await tester.request(path);
      final body = response.body;

      expect(body, contains('name="robots" content="noindex, follow"'));
      expect(body, isNot(contains('rel="alternate"')));
    });
  }
}
