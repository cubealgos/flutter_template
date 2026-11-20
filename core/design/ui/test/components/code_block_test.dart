import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/code_block.dart';

import '../support/app_harness.dart';

/// An arbitrary cap, just to prove [AppCodeBlock.maxHeight] is threaded
/// through to a [ConstrainedBox].
const double _cap = 120;

void main() {
  group('AppCodeBlock', () {
    testWidgets('renders its verbatim text', (tester) async {
      await tester.pumpWidget(
        testApp(const AppCodeBlock(text: '{"ok": true}')),
      );

      expect(find.text('{"ok": true}'), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(
        testApp(const AppCodeBlock(text: 'line one\nline two')),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('maxHeight: null lets the block grow unconstrained', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const AppCodeBlock(text: 'unconstrained')),
      );

      expect(
        find.descendant(
          of: find.byType(AppCodeBlock),
          matching: find.byType(ConstrainedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('maxHeight caps the block and adds a ConstrainedBox', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const AppCodeBlock(text: 'capped', maxHeight: _cap)),
      );

      final constrained = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(AppCodeBlock),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrained.constraints.maxHeight, _cap);
    });
  });
}
