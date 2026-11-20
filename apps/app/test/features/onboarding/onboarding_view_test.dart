import 'package:app/app/di.dart';
import 'package:app/features/onboarding/layouts/onboarding_desktop_layout.dart';
import 'package:app/features/onboarding/layouts/onboarding_mobile_layout.dart';
import 'package:app/features/onboarding/onboarding_view.dart';
import 'package:app/features/onboarding/steps/onboarding_saved_hint.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import '../../support/layout_harness.dart';

/// Smoke tests: the onboarding stepper's first step (Profile) renders in
/// both themes without throwing — no golden files, matching this
/// workspace's own testing conventions (`derive-tests-from-the-code-surface`).
void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpOnboarding(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: AppTheme(
            brightnessOverride: brightness,
            child: OnboardingView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the first step in light mode', (tester) async {
    await pumpOnboarding(tester, Brightness.light);

    expect(find.text(t.onboarding.stepProfileTitle), findsOneWidget);
    expect(find.text(t.onboarding.nextButton), findsOneWidget);
  });

  testWidgets('renders the first step in dark mode', (tester) async {
    await pumpOnboarding(tester, Brightness.dark);

    expect(find.text(t.onboarding.stepProfileTitle), findsOneWidget);
    expect(find.text(t.onboarding.nextButton), findsOneWidget);
  });

  testWidgets('the Preferences step shows "Saved" immediately, from its '
      'pre-selected default — never a state where "Personal use" reads '
      'selected but "Saved" has not appeared yet', (tester) async {
    await pumpOnboarding(tester, Brightness.light);

    await tester.tap(find.text(t.onboarding.nextButton));
    await tester.pumpAndSettle();

    expect(find.text(t.onboarding.stepPreferencesTitle), findsOneWidget);
    final hint = tester.widget<OnboardingSavedHint>(
      find.byType(OnboardingSavedHint),
    );
    expect(hint.visible, isTrue);
  });

  for (final (width, isDesktop) in [
    (mobileWidth, false),
    (desktopWidth, true),
  ]) {
    testWidgets('shows the ${isDesktop ? 'desktop' : 'mobile'} layout at a '
        '${width.toInt()}px viewport', (tester) async {
      tester.view
        ..physicalSize = Size(width, layoutHeight)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery.fromView(
            view: tester.view,
            child: AppTheme(child: OnboardingView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(OnboardingDesktopLayout),
        isDesktop ? findsOne : findsNothing,
      );
      expect(
        find.byType(OnboardingMobileLayout),
        isDesktop ? findsNothing : findsOne,
      );
    });
  }
}
