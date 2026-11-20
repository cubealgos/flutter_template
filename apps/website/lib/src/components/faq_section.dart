import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';

/// The landing page's FAQ section: an eyebrow, a heading and a list of
/// `<details>`/`<summary>` disclosures. Ports the reference site's `.faq`
/// section (`index.astro`) — native disclosure semantics (works with no
/// JS at all, keyboard-operable by default) progressively enhanced by
/// `web/motion.js`'s `initFaqDisclosure`, which animates the open/close
/// height via the Web Animations API instead of the browser's own
/// instant toggle; the chevron rotation stays pure CSS, driven off the
/// `open` attribute the native element already manages. Neutral
/// placeholder copy, square corners (no chamfer).
class FaqSection extends StatelessComponent {
  /// Creates the FAQ section.
  const FaqSection({required this.locale, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return section(
      id: 'faq',
      classes: 'faq-section',
      attributes: const {'aria-labelledby': 'faq-heading'},
      [
        div(
          classes: 'faq-section__inner',
          attributes: const {'data-reveal': ''},
          [
            p(classes: 'faq-section__eyebrow', [
              Component.text(strings.faqEyebrow),
            ]),
            h2(id: 'faq-heading', classes: 'faq-section__heading', [
              Component.text(strings.faqHeading),
            ]),
            div(classes: 'faq-section__list', [
              for (final faq in strings.faqs) _FaqItem(faq: faq),
            ]),
          ],
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessComponent {
  const _FaqItem({required this.faq});

  final FaqCopy faq;

  @override
  Component build(BuildContext context) {
    return details(classes: 'faq-item', [
      summary(classes: 'faq-item__question', [Component.text(faq.question)]),
      div(classes: 'faq-item__answer-wrap', [
        p(classes: 'faq-item__answer', [Component.text(faq.answer)]),
      ]),
    ]);
  }
}
