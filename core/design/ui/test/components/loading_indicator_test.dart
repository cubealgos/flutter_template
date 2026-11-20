import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/loading_indicator.dart';

import '../support/app_harness.dart';

/// A non-default diameter, used to prove [AppLoadingIndicator.diameter] is
/// actually applied rather than always falling back to its default.
const double _customDiameter = 40;

void main() {
  group('AppLoadingIndicator rendering', () {
    testWidgets('renders a rotating spinner at its default size', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(const AppLoadingIndicator()));
      await tester.pump();

      expect(find.byType(AnimatedRotation), findsOneWidget);
      final custom = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(custom.size, const Size(24, 24));
    });

    testWidgets('diameter overrides the default size', (tester) async {
      await tester.pumpWidget(
        testApp(const AppLoadingIndicator(diameter: _customDiameter)),
      );
      await tester.pump();

      final custom = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(custom.size, const Size(_customDiameter, _customDiameter));
    });

    testWidgets('keeps animating without throwing', (tester) async {
      await tester.pumpWidget(testApp(const AppLoadingIndicator()));

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });
  });
}
