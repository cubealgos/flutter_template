import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/icon_button.dart';
import 'package:ui/src/components/screen_header.dart';

import '../support/app_harness.dart';

/// The 44dp WCAG 2.5.8 minimum hit target every tappable control in this
/// package enforces — also the floor `AppScreenHeader` enforces for its
/// own row height (spec §1.1).
const double _minHitTarget = 44;

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

void main() {
  group('AppScreenHeader rendering', () {
    testWidgets('renders the title', (tester) async {
      await tester.pumpWidget(testApp(const AppScreenHeader(title: 'Home')));

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('back: null renders no back button', (tester) async {
      await tester.pumpWidget(testApp(const AppScreenHeader(title: 'Home')));

      expect(find.byType(AppIconButton), findsNothing);
    });

    testWidgets('renders trailing content after the title', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppScreenHeader(title: 'Home', trailing: Text('Trailing')),
        ),
      );

      expect(find.text('Trailing'), findsOneWidget);
    });
  });

  group('AppScreenHeader sizing', () {
    testWidgets('meets the 44px minimum row height', (tester) async {
      await tester.pumpWidget(testApp(const AppScreenHeader(title: 'Home')));

      final size = tester.getSize(find.byType(AppScreenHeader));
      expect(size.height, greaterThanOrEqualTo(_minHitTarget));
    });
  });

  group('AppScreenHeader back affordance', () {
    testWidgets('renders a back button with the given semantic label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(
          const AppScreenHeader(
            title: 'Settings',
            back: AppScreenHeaderBack(semanticLabel: 'Back', onPressed: _noop),
          ),
        ),
      );

      expect(find.byType(AppIconButton), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Back'))),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('tapping the back button calls onPressed', (tester) async {
      var backCalled = false;

      await tester.pumpWidget(
        testApp(
          AppScreenHeader(
            title: 'Settings',
            back: AppScreenHeaderBack(
              semanticLabel: 'Back',
              onPressed: () => backCalled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AppIconButton));
      await tester.pump();

      expect(backCalled, isTrue);
    });
  });
}
