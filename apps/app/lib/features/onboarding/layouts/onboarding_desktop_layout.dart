import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/onboarding/widgets/onboarding_bottom_bar.dart';
import 'package:app/features/onboarding/widgets/onboarding_screen_frame.dart';
import 'package:app/features/onboarding/widgets/step_progress_and_title.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The onboarding stepper from the desktop breakpoint: the whole card
/// (progress, step content, buttons) centered vertically with a fixed gap
/// before the buttons, matching `Onboarding-desktop-dark.dc.html`.
class OnboardingDesktopLayout extends StatelessWidget {
  /// Creates the layout.
  const OnboardingDesktopLayout({
    required this.currentStepIndex,
    required this.stepCount,
    required this.step,
    required this.scope,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  /// The zero-based index of the current step.
  final int currentStepIndex;

  /// The total number of steps.
  final int stepCount;

  /// The step being shown.
  final OnboardingStep step;

  /// The scope handed to the step's own content builder.
  final OnboardingStepScope scope;

  /// Called when the step is skipped.
  final VoidCallback onSkip;

  /// Called when the user goes back a step.
  final VoidCallback onBack;

  /// Called when the user advances to the next step.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final progress = StepProgressAndTitle(
      index: currentStepIndex,
      total: stepCount,
      title: step.title,
    );
    final content = step.builder(context, scope);
    final bottomBar = OnboardingBottomBar(
      skipsWithBottomButton: step.skip == OnboardingSkipAffordance.bottomButton,
      onSkip: onSkip,
      onBack: onBack,
      onNext: onNext,
    );

    return OnboardingScreenFrame(
      step: step,
      onBack: onBack,
      onSkip: onSkip,
      // Centered within the body's `maxHeight`, so the body's own
      // constraints are needed here (the breakpoint itself is
      // `ResponsiveLayout`'s, from the viewport).
      body: LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  progress,
                  const AppGap.v8(),
                  content,
                  const AppGap.v8(),
                  bottomBar,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
