import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/components/site_footer.dart';
import 'package:website/src/components/site_nav.dart';
import 'package:website/src/dom_extra.dart';
import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';

/// The chrome every page shares: a skip-to-content link (the first
/// focusable element, per the accessibility acceptance criterion), the
/// nav landmark, a `<main id="main-content">` landmark wrapping [content],
/// and the footer landmark.
class PageShell extends StatelessComponent {
  /// Wraps [content] in the shared site chrome.
  const PageShell({
    required this.locale,
    required this.slug,
    required this.content,
    super.key,
  });

  /// The current page's locale.
  final SiteLocale locale;

  /// The current page's locale-agnostic slug (passed through to
  /// [SiteNav]'s language switcher).
  final String slug;

  /// The page's own body content.
  final List<Component> content;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return Component.fragment([
      a(href: '#main-content', classes: 'skip-link', [
        Component.text(strings.skipToContent),
      ]),
      SiteNav(locale: locale, slug: slug),
      mainTag(content, id: 'main-content'),
      SiteFooter(locale: locale, slug: slug),
    ]);
  }
}
