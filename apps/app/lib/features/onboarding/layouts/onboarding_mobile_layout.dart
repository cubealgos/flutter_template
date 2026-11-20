import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/onboarding/widgets/onboarding_bottom_bar.dart';
import 'package:app/features/onboarding/widgets/onboarding_screen_frame.dart';
import 'package:app/features/onboarding/widgets/step_progress_and_title.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The onboarding stepper below the tablet breakpoint: the "Step X of N"
/// progress + centered step title, then the step's own content, then the
/// Back/Next (or "Not now"/"Continue") button pair. Top-anchored, the step
/// content filling the remaining space above a pinned button row
/// (`AppContentWrapper`'s default).
class OnboardingMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const OnboardingMobileLayout({
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          progress,
          const AppGap.v8(),
          Expanded(child: SingleChildScrollView(child: content)),
          const AppGap.v6(),
          bottomBar,
        ],
      ),
    );
  }
}
