// Small builder helpers here return widgets on purpose: they only pre-fill
// a layout's callbacks for the tests below.
// ignore_for_file: solid_lints/avoid_returning_widgets

import 'package:app/features/onboarding/layouts/onboarding_desktop_layout.dart';
import 'package:app/features/onboarding/layouts/onboarding_mobile_layout.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

const int _stepCount = 3;

const _step = OnboardingStep(id: 'demo', title: 'Demo step', builder: _content);

Widget _content(BuildContext _, OnboardingStepScope _) =>
    const Text('step content');

const _scope = OnboardingStepScope(answer: null, onChanged: _ignore);

void _ignore(dynamic _) => noop();

void main() {
  group('OnboardingMobileLayout at the mobile breakpoint', () {
    Widget layout({VoidCallback? onNext}) => OnboardingMobileLayout(
      currentStepIndex: 0,
      stepCount: _stepCount,
      step: _step,
      scope: _scope,
      onSkip: noop,
      onBack: noop,
      onNext: onNext ?? noop,
    );

    testWidgets('shows the title, the step content and the button pair', (
      tester,
    ) async {
      await pumpLayout(tester, layout(), width: mobileWidth);

      expect(find.text('Demo step'), findsOneWidget);
      expect(find.text('step content'), findsOneWidget);
      expect(find.text(t.onboarding.nextButton), findsOneWidget);
    });

    testWidgets('pins the button row to the bottom', (tester) async {
      await pumpLayout(tester, layout(), width: mobileWidth);

      final next = tester.getCenter(find.text(t.onboarding.nextButton)).dy;
      expect(next, greaterThan(bottomBand));
    });

    testWidgets('forwards the Next tap', (tester) async {
      var next = false;
      await pumpLayout(
        tester,
        layout(onNext: () => next = true),
        width: mobileWidth,
      );

      await tester.tap(find.text(t.onboarding.nextButton));
      expect(next, isTrue);
    });
  });

  group('OnboardingDesktopLayout at the desktop breakpoint', () {
    Widget layout({VoidCallback? onNext}) => OnboardingDesktopLayout(
      currentStepIndex: 0,
      stepCount: _stepCount,
      step: _step,
      scope: _scope,
      onSkip: noop,
      onBack: noop,
      onNext: onNext ?? noop,
    );

    testWidgets('shows the title, the step content and the button pair', (
      tester,
    ) async {
      await pumpLayout(tester, layout(), width: desktopWidth);

      expect(find.text('Demo step'), findsOneWidget);
      expect(find.text('step content'), findsOneWidget);
      expect(find.text(t.onboarding.nextButton), findsOneWidget);
    });

    testWidgets('centers the card: the button row is not pinned to the '
        'bottom', (tester) async {
      await pumpLayout(tester, layout(), width: desktopWidth);

      final next = tester.getCenter(find.text(t.onboarding.nextButton)).dy;
      expect(next, lessThan(bottomBand));
    });

    testWidgets('forwards the Next tap', (tester) async {
      var next = false;
      await pumpLayout(
        tester,
        layout(onNext: () => next = true),
        width: desktopWidth,
      );

      await tester.tap(find.text(t.onboarding.nextButton));
      expect(next, isTrue);
    });
  });
}
