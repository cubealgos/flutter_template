import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/i18n/site_strings.dart';

/// The landing page's proof section: a status badge, a heading, two supporting
/// paragraphs, a pair of stat cards (one count-up, one plain text) and a row of
/// short tag pills, closing with a link. Ports the reference site's proof
/// teaser with neutral placeholder copy — square corners (no chamfer), the same
/// `--color-surface` section background (every section follows the theme, this
/// one included) and the same count-up-on-scroll pattern (`web/motion.js`'s
/// `initCountUp`): the animating span is `aria-hidden`, a visually-hidden
/// sibling carries the real, final value so assistive tech never reads a
/// mid-animation number. The `aria-hidden` span's own initial text is the real,
/// final number too (not `'0'`) — `initCountUp` resets it to `0` only right
/// before it actually starts animating, and only when the visitor has not
/// requested reduced motion; with no JS at all (or under reduced motion), a
/// sighted visitor sees the real number immediately, never a stuck `'0'`.
class ProofSection extends StatelessComponent {
  /// Creates the proof section.
  const ProofSection({required this.locale, super.key});

  /// The current page's locale.
  final SiteLocale locale;

  @override
  Component build(BuildContext context) {
    final strings = SiteStrings.of(locale);

    return section(
      id: 'proof',
      classes: 'proof-section',
      attributes: const {'aria-labelledby': 'proof-heading'},
      [
        div(classes: 'proof-section__inner', [_copy(strings), _stats(strings)]),
      ],
    );
  }

  Component _copy(SiteStrings strings) {
    return div(
      classes: 'proof-section__copy',
      attributes: const {'data-reveal': ''},
      [
        span(classes: 'proof-section__badge', [
          const span(
            classes: 'proof-section__badge-dot',
            attributes: {'aria-hidden': 'true'},
            [],
          ),
          Component.text(strings.proofBadge),
        ]),
        h2(id: 'proof-heading', classes: 'proof-section__heading', [
          Component.text(strings.proofHeading),
        ]),
        p(classes: 'proof-section__body', [
          Component.text(strings.proofBodyOne),
        ]),
        p(classes: 'proof-section__body', [
          Component.text(strings.proofBodyTwo),
        ]),
        a(href: 'mailto:${strings.ctaEmail}', classes: 'proof-section__link', [
          Component.text(strings.proofLinkLabel),
        ]),
      ],
    );
  }

  Component _stats(SiteStrings strings) {
    return div(
      classes: 'proof-section__stats',
      attributes: const {'data-reveal': ''},
      [
        for (final stat in strings.proofStats)
          div(classes: 'proof-stat-card', [
            p(classes: 'proof-stat-card__value', [_statValue(stat)]),
            p(classes: 'proof-stat-card__label', [Component.text(stat.label)]),
          ]),
        ul(
          classes: 'proof-pills',
          attributes: {'aria-label': strings.proofPillsLabel},
          [
            for (final pill in strings.proofPills)
              li(classes: 'proof-pill', [Component.text(pill)]),
          ],
        ),
      ],
    );
  }

  Component _statValue(StatCopy stat) {
    final countTo = stat.countTo;
    if (countTo == null) return Component.text(stat.value);

    return Component.fragment([
      span(
        attributes: const {'aria-hidden': 'true'},
        [
          span(
            classes: 'proof-stat-card__count',
            attributes: {'data-count-to': '$countTo'},
            [Component.text('$countTo')],
          ),
          Component.text(stat.value.replaceFirst('$countTo', '')),
        ],
      ),
      span(classes: 'visually-hidden', [Component.text(stat.value)]),
    ]);
  }
}
