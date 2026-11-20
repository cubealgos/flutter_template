import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';

/// The landing page's closing call-to-action band — ports `CTASection`'s
/// full-width, single-accent-band structure (square corners, no chamfer).
class CtaSection extends StatelessComponent {
  /// Creates the closing CTA band.
  const CtaSection({required this.locale, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return section(
      classes: 'cta-section',
      attributes: const {'aria-labelledby': 'final-cta-heading'},
      [
        div(
          classes: 'cta-section__inner',
          attributes: const {'data-reveal': ''},
          [
            div(classes: 'cta-section__copy', [
              h2(id: 'final-cta-heading', classes: 'cta-section__heading', [
                Component.text(strings.ctaHeading),
              ]),
              p(classes: 'cta-section__body', [
                Component.text(strings.ctaBody),
              ]),
            ]),
            a(
              href: 'mailto:${strings.ctaEmail}',
              classes: 'cta-section__button',
              [Component.text(strings.ctaLabel)],
            ),
          ],
        ),
      ],
    );
  }
}
