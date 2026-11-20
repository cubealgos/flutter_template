import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/icon_button.dart';
import 'package:ui/src/components/screen_header.dart';
import 'package:ui/src/layout/content_wrapper.dart';
import 'package:ui/src/layout/screen_scaffold.dart';

import '../support/app_harness.dart';

/// Wider than every `AppContentWidth` preset, so a body this size is
/// always the one being capped, never the other way around.
const double _widerThanEveryPreset = 2000;

/// A fixed, arbitrary height for the sizing probe below.
const double _probeHeight = 10;

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

void main() {
  group('AppScreenScaffold rendering', () {
    testWidgets('renders the title and body', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppScreenScaffold(
            title: 'Settings',
            body: Text('Body content'),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Body content'), findsOneWidget);
    });

    testWidgets('back: null renders no back button', (tester) async {
      await tester.pumpWidget(
        testApp(const AppScreenScaffold(title: 'Home', body: Text('Body'))),
      );

      expect(find.byType(AppIconButton), findsNothing);
    });
  });

  group('AppScreenScaffold back affordance', () {
    testWidgets('a back affordance renders a back button', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppScreenScaffold(
            title: 'Settings',
            body: Text('Body'),
            back: AppScreenHeaderBack(semanticLabel: 'Back', onPressed: _noop),
          ),
        ),
      );

      expect(find.byType(AppIconButton), findsOneWidget);
    });
  });

  group('AppScreenScaffold scrolling', () {
    testWidgets('scrollable: true wraps the body in a scroll view', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const AppScreenScaffold(title: 'Settings', body: Text('Body'))),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('scrollable: false does not add a scroll view', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AppScreenScaffold(
            title: 'Settings',
            body: Text('Body'),
            scrollable: false,
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });

  group('AppScreenScaffold width capping', () {
    testWidgets('caps content to the given AppContentWidth preset', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppScreenScaffold(
            title: 'Sign in',
            body: SizedBox(
              width: _widerThanEveryPreset,
              height: _probeHeight,
              key: Key('body'),
            ),
            contentWidth: AppContentWidth.auth,
          ),
        ),
      );

      final size = tester.getSize(find.byKey(const Key('body')));
      expect(size.width, lessThanOrEqualTo(AppContentWidth.auth.maxWidth));
    });
  });

  group('AppScreenScaffold header layouts', () {
    testWidgets('headerFillsWidth: true still renders title and body', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppScreenScaffold(
            title: 'Home',
            body: Text('Body'),
            headerFillsWidth: true,
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}
