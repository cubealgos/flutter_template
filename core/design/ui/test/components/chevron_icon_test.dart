import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/chevron_icon.dart';

import '../support/app_harness.dart';

/// How many `AppChevronIcon`s the "both directions" test renders.
const int _bothDirections = 2;

void main() {
  group('AppChevronIcon', () {
    testWidgets('renders at its fixed 20x20 size', (tester) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: AppChevronIcon(direction: AppChevronDirection.start),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppChevronIcon));
      expect(size, const Size(20, 20));
    });

    testWidgets('carries no semantics of its own (purely decorative)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const Center(
            child: AppChevronIcon(direction: AppChevronDirection.end),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppChevronIcon)),
        isNot(isSemantics(isButton: true)),
      );
      handle.dispose();
    });

    testWidgets('start and end directions both render without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const Column(
            children: [
              AppChevronIcon(direction: AppChevronDirection.start),
              AppChevronIcon(direction: AppChevronDirection.end),
            ],
          ),
        ),
      );

      expect(find.byType(AppChevronIcon), findsNWidgets(_bothDirections));
    });
  });
}
