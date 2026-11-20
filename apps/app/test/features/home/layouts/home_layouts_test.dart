// Small builder helpers here return widgets on purpose: they only pre-fill
// a layout's callbacks for the tests below.
// ignore_for_file: solid_lints/avoid_returning_widgets

import 'package:app/features/home/home_model.dart';
import 'package:app/features/home/layouts/home_desktop_layout.dart';
import 'package:app/features/home/layouts/home_mobile_layout.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

const List<HomeSetupItem> _steps = [(id: 'profile', title: 'Profile')];

Widget _mobile({VoidCallback? onSignOut, bool showSetupCard = true}) =>
    HomeMobileLayout(
      showSetupCard: showSetupCard,
      completedStepCount: 0,
      totalStepCount: 1,
      openSteps: _steps,
      onDismissSetupCard: noop,
      onOpenOnboarding: noop,
      onSignOut: onSignOut ?? noop,
      onOpenSettings: noop,
    );

Widget _desktop({VoidCallback? onSignOut, bool showSetupCard = true}) =>
    HomeDesktopLayout(
      showSetupCard: showSetupCard,
      completedStepCount: 0,
      totalStepCount: 1,
      openSteps: _steps,
      onDismissSetupCard: noop,
      onOpenOnboarding: noop,
      onSignOut: onSignOut ?? noop,
      onOpenSettings: noop,
    );

void main() {
  group('HomeMobileLayout at the mobile breakpoint', () {
    testWidgets('shows the card, empty state and sign-out button', (
      tester,
    ) async {
      await pumpLayout(tester, _mobile(), width: mobileWidth);

      expect(find.text(t.home.setupCardTitle), findsOneWidget);
      expect(find.text(t.home.emptyStateMessage), findsOneWidget);
      expect(find.text(t.home.signOutButton), findsOneWidget);
    });

    testWidgets('pins the sign-out button to the bottom, card on top', (
      tester,
    ) async {
      await pumpLayout(tester, _mobile(), width: mobileWidth);

      final card = tester.getTopLeft(find.text(t.home.setupCardTitle)).dy;
      final button = tester.getCenter(find.text(t.home.signOutButton)).dy;
      expect(card, lessThan(middle));
      expect(button, greaterThan(bottomBand));
    });

    testWidgets('hides the card when showSetupCard is false', (tester) async {
      await pumpLayout(
        tester,
        _mobile(showSetupCard: false),
        width: mobileWidth,
      );

      expect(find.text(t.home.setupCardTitle), findsNothing);
    });

    testWidgets('forwards the sign-out tap', (tester) async {
      var signedOut = false;
      await pumpLayout(
        tester,
        _mobile(onSignOut: () => signedOut = true),
        width: mobileWidth,
      );

      await tester.tap(find.text(t.home.signOutButton));
      expect(signedOut, isTrue);
    });
  });

  group('HomeDesktopLayout at the desktop breakpoint', () {
    testWidgets('shows the card, empty state and sign-out button', (
      tester,
    ) async {
      await pumpLayout(tester, _desktop(), width: desktopWidth);

      expect(find.text(t.home.setupCardTitle), findsOneWidget);
      expect(find.text(t.home.emptyStateMessage), findsOneWidget);
      expect(find.text(t.home.signOutButton), findsOneWidget);
    });

    testWidgets('centers the whole group: the sign-out button is not pinned '
        'to the bottom', (tester) async {
      await pumpLayout(tester, _desktop(), width: desktopWidth);

      final button = tester.getCenter(find.text(t.home.signOutButton)).dy;
      expect(button, lessThan(bottomBand));
    });

    testWidgets('forwards the sign-out tap', (tester) async {
      var signedOut = false;
      await pumpLayout(
        tester,
        _desktop(onSignOut: () => signedOut = true),
        width: desktopWidth,
      );

      await tester.tap(find.text(t.home.signOutButton));
      expect(signedOut, isTrue);
    });
  });
}
