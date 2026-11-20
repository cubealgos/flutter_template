import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';

/// The landing page's process section: an eyebrow, a heading and a
/// numbered list of steps (an ordered list, `<ol>`, since the steps run
/// in a fixed sequence). Ports the reference site's `.process` section
/// (`index.astro`) — an eyebrow/heading pair above a responsive step
/// grid, each step revealed on scroll with a staggered delay, plus a
/// connecting line between steps at wide viewports — with neutral
/// placeholder copy and square corners (no chamfer).
class ProcessSection extends StatelessComponent {
  /// Creates the process section.
  const ProcessSection({required this.locale, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return section(
      id: 'process',
      classes: 'process-section',
      attributes: const {'aria-labelledby': 'process-heading'},
      [
        div(classes: 'process-section__inner', [
          p(classes: 'process-section__eyebrow', [
            Component.text(strings.processEyebrow),
          ]),
          h2(id: 'process-heading', classes: 'process-section__heading', [
            Component.text(strings.processHeading),
          ]),
          ol(
            classes: 'process-section__steps',
            attributes: const {'data-reveal-group': ''},
            [
              for (final (index, step) in strings.processSteps.indexed)
                li(
                  classes: 'process-step',
                  attributes: const {'data-reveal': ''},
                  [
                    span(classes: 'process-step__num', [
                      Component.text('${index + 1}'),
                    ]),
                    h3(classes: 'process-step__title', [
                      Component.text(step.title),
                    ]),
                    p(classes: 'process-step__body', [
                      Component.text(step.body),
                    ]),
                  ],
                ),
            ],
          ),
        ]),
      ],
    );
  }
}
