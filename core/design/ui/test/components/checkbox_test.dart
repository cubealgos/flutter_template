import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/checkbox.dart';

import '../support/app_harness.dart';

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noopChanged(bool? _) {}

void main() {
  group('AppCheckbox rendering and accessibility', () {
    testWidgets('renders its visible label and accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppCheckbox(
            label: 'Accept terms',
            value: false,
            onChanged: _noopChanged,
          ),
        ),
      );

      expect(find.text('Accept terms'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Accept terms'))),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('keyboard focus is reflected in semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppCheckbox(
            label: 'Accept terms',
            value: false,
            onChanged: _noopChanged,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Accept terms'))),
        isSemantics(isFocused: true, isFocusable: true),
      );
      handle.dispose();
    });
  });

  group('AppCheckbox interaction', () {
    testWidgets('tapping an unchecked box calls onChanged with true', (
      tester,
    ) async {
      bool? nextValue;

      await tester.pumpWidget(
        testApp(
          AppCheckbox(
            label: 'Accept terms',
            value: false,
            onChanged: (value) => nextValue = value,
          ),
        ),
      );
      await tester.tap(find.byType(AppCheckbox));
      await tester.pump();

      expect(nextValue, isTrue);
    });
  });

  group('AppCheckbox toggling', () {
    testWidgets('value: true reports checked and toggles to false', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      bool? nextValue;

      await tester.pumpWidget(
        testApp(
          AppCheckbox(
            label: 'Accept terms',
            value: true,
            onChanged: (value) => nextValue = value,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Accept terms'))),
        isSemantics(hasCheckedState: true, isChecked: true),
      );

      await tester.tap(find.byType(AppCheckbox));
      await tester.pump();

      expect(nextValue, isFalse);
      handle.dispose();
    });

    testWidgets('enabled: false blocks the tap and reports as disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var called = false;

      await tester.pumpWidget(
        testApp(
          AppCheckbox(
            label: 'Accept terms',
            value: false,
            enabled: false,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tap(find.byType(AppCheckbox));
      await tester.pump();

      expect(called, isFalse);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Accept terms'))),
        isSemantics(hasCheckedState: true, hasEnabledState: true),
      );
      handle.dispose();
    });
  });

  group('AppCheckbox pointer states', () {
    testWidgets('hovering does not throw and keeps the checkbox in the tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppCheckbox(
            label: 'Accept terms',
            value: false,
            onChanged: _noopChanged,
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(AppCheckbox)));
      await tester.pump();

      expect(find.byType(AppCheckbox), findsOneWidget);
    });
  });
}
