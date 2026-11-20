import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The bottom Back/Next (or "Not now"/"Continue") button pair — always
/// enabled, on every step (see `OnboardingView`'s `back` dartdoc).
class OnboardingBottomBar extends StatelessWidget {
  /// Creates the bar.
  const OnboardingBottomBar({
    required this.skipsWithBottomButton,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  /// Whether the current step's secondary button is "Not now" (skip)
  /// rather than "Back".
  final bool skipsWithBottomButton;

  /// Called when the secondary button is "Not now" and is pressed.
  final VoidCallback onSkip;

  /// Called when the secondary button is "Back" and is pressed.
  final VoidCallback onBack;

  /// Called when the primary button is pressed.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = skipsWithBottomButton
        ? t.common.notNow
        : t.common.back;
    final primaryLabel = skipsWithBottomButton
        ? t.common.continueLabel
        : t.onboarding.nextButton;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            semanticLabel: secondaryLabel,
            variant: AppButtonVariant.secondary,
            onPressed: skipsWithBottomButton ? onSkip : onBack,
            child: Text(secondaryLabel),
          ),
        ),
        const AppGap.h4(),
        Expanded(
          child: AppButton(
            semanticLabel: primaryLabel,
            onPressed: onNext,
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
