import 'package:jaspr/jaspr.dart';

import 'package:website/src/components/cta_section.dart';
import 'package:website/src/components/faq_section.dart';
import 'package:website/src/components/feature_grid.dart';
import 'package:website/src/components/hero.dart';
import 'package:website/src/components/process_section.dart';
import 'package:website/src/components/proof_section.dart';
import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';
import 'package:website/src/page_shell.dart';
import 'package:website/src/seo_head.dart';

/// The landing page: hero, two bento-style grids ("what you get", "what
/// we build"), a proof section, a process section, a FAQ section and a
/// closing CTA — ports the reference site's home-page section order and
/// spacing rhythm (`index.astro`), with neutral placeholder copy and no
/// real branding.
class HomePage extends StatelessComponent {
  /// Creates the landing page for [locale].
  const HomePage({required this.locale, super.key});

  /// The page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return Component.fragment([
      SeoHead(
        locale: locale,
        title: strings.homeTitle,
        description: strings.homeDescription,
        slug: '',
      ),
      PageShell(
        locale: locale,
        slug: '',
        content: [
          Hero(locale: locale),
          FeatureGrid(
            id: 'what-you-get',
            headingId: 'what-you-get-heading',
            eyebrow: strings.featuresEyebrow,
            heading: strings.featuresHeading,
            cards: strings.features,
          ),
          FeatureGrid(
            id: 'what-we-build',
            headingId: 'what-we-build-heading',
            eyebrow: strings.servicesEyebrow,
            heading: strings.servicesHeading,
            cards: strings.services,
          ),
          ProofSection(locale: locale),
          ProcessSection(locale: locale),
          FaqSection(locale: locale),
          CtaSection(locale: locale),
        ],
      ),
    ]);
  }
}
