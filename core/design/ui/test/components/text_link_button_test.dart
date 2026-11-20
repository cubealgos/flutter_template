import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/text_link_button.dart';

import '../support/app_harness.dart';

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

/// The package-wide minimum hit target, matching `AppTextLinkButton`'s own
/// `_minHitTarget`.
const double _minHitTarget = 48;

/// An arbitrary row width narrower than the combined natural width of the
/// three footer links below, so a regression back to full-width sizing
/// would force each onto its own line.
const double _footerRowWidth = 342;

void main() {
  group('AppTextLinkButton rendering and accessibility', () {
    testWidgets('renders its visible text and accessible name', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppTextLinkButton(
            label: 'Use a different email',
            onPressed: _noop,
          ),
        ),
      );

      expect(find.text('Use a different email'), findsOneWidget);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('Use a different email')),
        ),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('semanticLabel overrides the accessible name', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppTextLinkButton(
            label: 'Resend code',
            semanticLabel: 'Resend the sign-in code',
            onPressed: _noop,
          ),
        ),
      );

      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('Resend the sign-in code')),
        ),
        isSemantics(isButton: true),
      );
      handle.dispose();
    });
  });

  group('AppTextLinkButton interaction', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppTextLinkButton(
            label: 'Manage in Settings',
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.tap(find.byType(AppTextLinkButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('meets the 44px minimum hit target despite small text', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppTextLinkButton(label: 'Resend code', onPressed: _noop),
        ),
      );

      final size = tester.getSize(find.byType(AppTextLinkButton));
      expect(size.height, greaterThanOrEqualTo(_minHitTarget));
    });
  });

  group('AppTextLinkButton sizing inside a Wrap', () {
    testWidgets('shrink-wraps to its label width, not the row width', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: SizedBox(
              width: _footerRowWidth,
              child: Wrap(
                children: <Widget>[
                  AppTextLinkButton(label: 'Legal', onPressed: _noop),
                  AppTextLinkButton(
                    label: 'Terms & Conditions',
                    onPressed: _noop,
                  ),
                  AppTextLinkButton(label: 'Privacy Policy', onPressed: _noop),
                ],
              ),
            ),
          ),
        ),
      );

      final legalWidth = tester.getSize(find.text('Legal')).width;
      final buttonWidth = tester
          .getSize(find.byType(AppTextLinkButton).first)
          .width;
      expect(buttonWidth, lessThan(legalWidth + _minHitTarget));
    });
  });
}
