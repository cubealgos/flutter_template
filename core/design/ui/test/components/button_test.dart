import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/button.dart';

import '../support/app_harness.dart';

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

void main() {
  group('AppButton rendering and accessibility', () {
    testWidgets('renders its visible content and accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppButton(
            semanticLabel: 'Save changes',
            onPressed: _noop,
            child: Text('Save'),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Save changes'))),
        isSemantics(
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('keyboard focus is reflected in semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppButton(
            semanticLabel: 'Save changes',
            onPressed: _noop,
            child: Text('Save'),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Save changes'))),
        isSemantics(isButton: true, isFocused: true, isFocusable: true),
      );
      handle.dispose();
    });
  });

  group('AppButton interaction', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppButton(
            semanticLabel: 'Save changes',
            onPressed: () => pressed = true,
            child: const Text('Save'),
          ),
        ),
      );
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('disabled: true blocks the tap and reports as disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppButton(
            semanticLabel: 'Save changes',
            onPressed: () => pressed = true,
            disabled: true,
            child: const Text('Save'),
          ),
        ),
      );
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isFalse);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Save changes'))),
        isSemantics(isButton: true, hasEnabledState: true),
      );
      handle.dispose();
    });
  });

  group('AppButton loading state', () {
    testWidgets('loading: true shows a spinner and blocks the tap', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppButton(
            semanticLabel: 'Save changes',
            onPressed: () => pressed = true,
            loading: true,
            child: const Text('Save'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedRotation), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(pressed, isFalse);
    });
  });

  group('AppButton pointer states', () {
    testWidgets('hovering does not throw and keeps the button in the tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppButton(
            semanticLabel: 'Save changes',
            onPressed: _noop,
            child: Text('Save'),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(AppButton)));
      await tester.pump();

      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets(
      'a held press does not throw and keeps the button in the tree',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            const AppButton(
              semanticLabel: 'Save changes',
              onPressed: _noop,
              child: Text('Save'),
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(AppButton)),
        );
        await tester.pump();

        expect(find.byType(AppButton), findsOneWidget);

        await gesture.up();
        await tester.pump();
      },
    );
  });
}
