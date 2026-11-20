import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/tokens.g.dart';

import '../support/app_harness.dart';

/// WCAG 2.x's flare term, added to both luminances in the contrast ratio.
const double _flare = 0.05;

/// WCAG AA's minimum contrast for normal-size text.
const double _aaNormalText = 4.5;

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (lighter, darker) = la > lb ? (la, lb) : (lb, la);

  return (lighter + _flare) / (darker + _flare);
}

void main() {
  // Filled-button labels and the checkbox mark sit on `accent` and
  // `danger`. In dark mode `on-accent` must be ground-coloured, not white
  // (spec.md §1.3): white measured 2.15:1 on dark `danger`.
  for (final brightness in Brightness.values) {
    for (final fill in const [colorAccent, colorDanger]) {
      testWidgets('on-accent clears AA on ${fill.name} '
          'in ${brightness.name}', (tester) async {
        await tester.pumpWidget(
          testApp(const SizedBox.shrink(), brightness: brightness),
        );
        final context = tester.element(find.byType(SizedBox));

        expect(
          _contrast(colorOnAccent.resolve(context), fill.resolve(context)),
          greaterThanOrEqualTo(_aaNormalText),
        );
      });
    }
  }
}
