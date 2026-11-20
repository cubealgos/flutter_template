import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:website/src/i18n/site_strings.dart';

/// A landing-page bento-style grid: an asymmetric grid (one hero cell,
/// normal cells, one wide cell) of [FeatureCardCopy] cells — ports the
/// reference site's `BentoSection`/`ServiceCard` structure and spacing rhythm
/// (see `web/site.css`'s `.feature-grid`/`.feature-card` rules and their
/// breakpoints), square corners (no chamfer), neutral placeholder copy.
///
/// Used twice on the landing page (`HomePage`) with different copy: once
/// for the plain "what you get" grid, once for the "what we build" grid
/// whose cards link out (`FeatureCardCopy.href`/`linkLabel` set) — mirrors
/// the reference site's `index.astro`, which renders two `BentoSection`s from
/// the same component for exactly this reason.
class FeatureGrid extends StatelessComponent {
  /// Creates a bento-style feature/service grid section.
  const FeatureGrid({
    required this.id,
    required this.headingId,
    required this.eyebrow,
    required this.heading,
    required this.cards,
    super.key,
  });

  /// The section's anchor id, linked to from the nav/footer/hero.
  final String id;

  /// The heading's element id, referenced by `aria-labelledby`.
  final String headingId;

  /// The small label above [heading].
  final String eyebrow;

  /// The section heading.
  final String heading;

  /// The grid's cards, in DOM order.
  final List<FeatureCardCopy> cards;

  @override
  Component build(BuildContext context) {
    return section(
      id: id,
      classes: 'feature-section',
      attributes: {'aria-labelledby': headingId},
      [
        div(classes: 'feature-section__inner', [
          p(classes: 'feature-section__eyebrow', [Component.text(eyebrow)]),
          h2(
            id: headingId,
            classes: 'feature-section__heading',
            attributes: const {'data-reveal': ''},
            [Component.text(heading)],
          ),
          div(
            classes: 'feature-grid',
            attributes: const {'data-reveal-group': ''},
            [for (final card in cards) _FeatureCard(card: card)],
          ),
        ]),
      ],
    );
  }
}

class _FeatureCard extends StatelessComponent {
  const _FeatureCard({required this.card});

  final FeatureCardCopy card;

  @override
  Component build(BuildContext context) {
    final href = card.href;
    final linkLabel = card.linkLabel;
    final classes =
        'feature-card feature-card--${card.size}'
        '${href != null ? ' feature-card--interactive' : ''}';
    final children = [
      h3(classes: 'feature-card__title', [Component.text(card.title)]),
      p(classes: 'feature-card__description', [
        Component.text(card.description),
      ]),
      if (href != null && linkLabel != null)
        span(
          classes: 'feature-card__link',
          attributes: const {'aria-hidden': 'true'},
          [Component.text(linkLabel)],
        ),
    ];

    if (href != null) {
      return a(
        href: href,
        classes: classes,
        attributes: const {'data-reveal': ''},
        children,
      );
    }

    return div(
      classes: classes,
      attributes: const {'data-reveal': ''},
      children,
    );
  }
}
