import 'package:app/app/di.dart';
import 'package:app/app/preference_keys.dart';
import 'package:app/features/home/home_view.dart';
import 'package:app/features/home/layouts/home_desktop_layout.dart';
import 'package:app/features/home/layouts/home_mobile_layout.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import '../../support/layout_harness.dart';

/// Smoke tests: Home renders in both themes without throwing — no golden
/// files, matching this workspace's own testing conventions
/// (`derive-tests-from-the-code-surface`).
void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpHome(
    WidgetTester tester,
    Brightness brightness, {
    double? width,
  }) async {
    if (width != null) {
      tester.view
        ..physicalSize = Size(width, layoutHeight)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    // Pre-seeded so `HomeController.init` doesn't try to show the push
    // permission pre-prompt as an overlay — there is no `Navigator` in
    // this smoke test's tree for `OverlayDialogService` to attach to;
    // that behaviour has its own coverage in `home_controller_test.dart`.
    await getIt<UserPreferences>().update(<String, dynamic>{
      pushPermissionPromptShownPreferenceKey: true,
    });
    final home = AppTheme(brightnessOverride: brightness, child: HomeView());
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        // With a `width`, follow the (resizable) test view so a test can
        // cross a breakpoint after the first pump.
        child: width == null
            ? MediaQuery(data: const MediaQueryData(), child: home)
            : MediaQuery.fromView(view: tester.view, child: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the empty state and the setup card in light mode', (
    tester,
  ) async {
    await pumpHome(tester, Brightness.light);

    expect(find.text(t.home.title), findsOneWidget);
    expect(find.text(t.home.emptyStateMessage), findsOneWidget);
    expect(find.text(t.home.setupCardTitle), findsOneWidget);
    expect(find.text(t.home.signOutButton), findsOneWidget);
  });

  testWidgets('renders the empty state and the setup card in dark mode', (
    tester,
  ) async {
    await pumpHome(tester, Brightness.dark);

    expect(find.text(t.home.title), findsOneWidget);
    expect(find.text(t.home.emptyStateMessage), findsOneWidget);
    expect(find.text(t.home.setupCardTitle), findsOneWidget);
    expect(find.text(t.home.signOutButton), findsOneWidget);
  });

  testWidgets('shows the mobile layout on a phone-width viewport', (
    tester,
  ) async {
    await pumpHome(tester, Brightness.light, width: mobileWidth);

    expect(find.byType(HomeMobileLayout), findsOneWidget);
    expect(find.byType(HomeDesktopLayout), findsNothing);
  });

  testWidgets('shows the desktop layout on a desktop-width viewport, and '
      'keeps the controller across the breakpoint', (tester) async {
    await pumpHome(tester, Brightness.light, width: mobileWidth);
    final before = tester.state(find.byType(HomeView));

    tester.view.physicalSize = const Size(desktopWidth, layoutHeight);
    await tester.pumpAndSettle();

    expect(find.byType(HomeDesktopLayout), findsOneWidget);
    expect(find.byType(HomeMobileLayout), findsNothing);
    expect(tester.state(find.byType(HomeView)), same(before));
  });
}
