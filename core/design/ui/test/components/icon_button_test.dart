import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/chevron_icon.dart';
import 'package:ui/src/components/icon_button.dart';

import '../support/app_harness.dart';

/// The 44dp WCAG 2.5.8 minimum hit target every tappable control in this
/// package enforces.
const double _minHitTarget = 44;

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

void main() {
  group('AppIconButton accessibility', () {
    testWidgets('exposes semanticLabel as its accessible name', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppIconButton(
            icon: AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: _noop,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Back'))),
        isSemantics(
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('keyboard focus is reflected in semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppIconButton(
            icon: AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: _noop,
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Back'))),
        isSemantics(isButton: true, isFocused: true),
      );
      handle.dispose();
    });
  });

  group('AppIconButton sizing', () {
    testWidgets('meets the 44x44 minimum hit target', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppIconButton(
            icon: AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: _noop,
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(_minHitTarget));
      expect(size.height, greaterThanOrEqualTo(_minHitTarget));
    });
  });

  group('AppIconButton interaction', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppIconButton(
            icon: const AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.tap(find.byType(AppIconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('disabled: true blocks the tap', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppIconButton(
            icon: const AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: () => pressed = true,
            disabled: true,
          ),
        ),
      );
      await tester.tap(find.byType(AppIconButton));
      await tester.pump();

      expect(pressed, isFalse);
    });
  });

  group('AppIconButton inert state', () {
    testWidgets('onPressed: null renders an inert button', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppIconButton(
            icon: AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: null,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Back'))),
        isNot(isSemantics(hasTapAction: true)),
      );
      handle.dispose();
    });
  });

  group('AppIconButton pointer states', () {
    testWidgets('hovering does not throw and keeps the button in the tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppIconButton(
            icon: AppChevronIcon(direction: AppChevronDirection.start),
            semanticLabel: 'Back',
            onPressed: _noop,
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(AppIconButton)));
      await tester.pump();

      expect(find.byType(AppIconButton), findsOneWidget);
    });
  });
}
