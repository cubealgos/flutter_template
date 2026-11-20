import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';

/// The landing page's hero band: a left content column (eyebrow, `<h1>`,
/// lede, two CTAs, a small supporting note) and a right-hand
/// compositional area carrying a large decorative background motif plus
/// a small "how a project moves" process diagram (Plan → Build → Ship).
/// Ports the reference site's `Hero.astro` content hierarchy, two-column layout
/// and spacing rhythm (see `web/site.css`'s `.hero*` rules) — square
/// corners throughout (no `--chamfer`/clip-path). The motif itself is
/// three layered, outlined (not filled) squares of decreasing size at
/// low opacity — the square-cornered equivalent of the reference site's
/// chamfer-ringed logo mark, evoking a stack of cube faces without an
/// actual 3D projection — bleeding off the top/right edge the same way
/// the reference site's own motif does. The content block plus the diagram's
/// own steps opt into the scroll-reveal motion (`data-reveal`/
/// `data-reveal-group`, `web/motion.js`).
class Hero extends StatelessComponent {
  /// Creates the hero band.
  const Hero({required this.locale, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return section(
      classes: 'hero',
      attributes: const {'aria-labelledby': 'hero-heading'},
      [
        div(classes: 'hero__inner', [_content(strings), _motifArea(strings)]),
      ],
    );
  }

  Component _content(SiteStrings strings) {
    return div(
      classes: 'hero__content',
      attributes: const {'data-reveal': ''},
      [
        p(classes: 'hero__eyebrow', [Component.text(strings.heroEyebrow)]),
        h1(id: 'hero-heading', classes: 'hero__headline', [
          Component.text(strings.heroHeadline),
        ]),
        p(classes: 'hero__lede', [Component.text(strings.heroLede)]),
        div(classes: 'hero__ctas', [
          a(
            href: 'mailto:${strings.ctaEmail}',
            classes: 'hero__cta hero__cta--primary',
            [Component.text(strings.heroPrimaryCtaLabel)],
          ),
          a(
            href: '${locale.resolve('')}#what-you-get',
            classes: 'hero__cta hero__cta--secondary',
            [
              span(classes: 'hero__cta--secondary__label', [
                Component.text(strings.heroSecondaryCtaLabel),
              ]),
            ],
          ),
        ]),
        p(classes: 'hero__note', [Component.text(strings.heroNote)]),
      ],
    );
  }

  Component _motifArea(SiteStrings strings) {
    return div(
      classes: 'hero__motif-area',
      attributes: const {'data-reveal': ''},
      [
        const div(
          classes: 'hero__shape',
          attributes: {'aria-hidden': 'true'},
          [div(classes: 'hero__shape-core', [])],
        ),
        _diagram(strings),
      ],
    );
  }

  Component _diagram(SiteStrings strings) {
    return div(
      classes: 'hero__diagram',
      attributes: {'role': 'img', 'aria-label': strings.heroDiagramLabel},
      [
        p(classes: 'hero__diagram-caption', [
          Component.text(strings.heroDiagramCaption),
        ]),
        div(
          classes: 'hero__diagram-flow',
          attributes: const {'data-reveal-group': ''},
          [
            for (final step in strings.heroDiagramSteps)
              div(
                classes: 'hero__diagram-step',
                attributes: const {'data-reveal': ''},
                [
                  div(classes: 'hero__diagram-node', [
                    span(classes: 'hero__diagram-node-label', [
                      Component.text(step.label),
                    ]),
                    span(classes: 'hero__diagram-node-sub', [
                      Component.text(step.sub),
                    ]),
                  ]),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
