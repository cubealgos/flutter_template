import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/list_tile.dart';

import '../support/app_harness.dart';

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noopTap() {}

void main() {
  group('AppListTile rendering', () {
    testWidgets('renders title and subtitle text', (tester) async {
      await tester.pumpWidget(
        testApp(const AppListTile(title: 'Wi-Fi', subtitle: 'Connected')),
      );

      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('renders leading and trailing content', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppListTile(
            title: 'Wi-Fi',
            leading: Text('L'),
            trailing: Text('T'),
          ),
        ),
      );

      expect(find.text('L'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('without onTap, the row is not a button and not focusable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(testApp(const AppListTile(title: 'Wi-Fi')));

      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(AppListTile)),
        isNot(isSemantics(isButton: true)),
      );
      handle.dispose();
    });
  });

  group('AppListTile interaction', () {
    testWidgets('when onTap is set, exposes title as the accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppListTile(
            title: 'Wi-Fi',
            subtitle: 'Connected',
            onTap: _noopTap,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Wi-Fi'))),
        isSemantics(
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hint: 'Connected',
        ),
      );
      handle.dispose();
    });

    testWidgets('tapping calls onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        testApp(AppListTile(title: 'Wi-Fi', onTap: () => tapped = true)),
      );
      await tester.tap(find.byType(AppListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('AppListTile pointer states', () {
    testWidgets('hovering a tappable tile does not throw', (tester) async {
      await tester.pumpWidget(
        testApp(const AppListTile(title: 'Wi-Fi', onTap: _noopTap)),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(AppListTile)));
      await tester.pump();

      expect(find.byType(AppListTile), findsOneWidget);
    });

    testWidgets('keyboard focus on a tappable tile is reflected in semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppListTile(title: 'Wi-Fi', onTap: _noopTap)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Wi-Fi'))),
        isSemantics(isButton: true, isFocused: true),
      );
      handle.dispose();
    });
  });
}
