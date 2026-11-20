import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The onboarding screen chrome shared by every layout: `AppScreenScaffold`
/// with the back chevron and the optional "Skip for now" link (an empty
/// `title`, since the stepper's own "Step X of N" progress + centered step
/// title render below it, inside [body]), around a layout-specific [body].
class OnboardingScreenFrame extends StatelessWidget {
  /// Creates the frame.
  const OnboardingScreenFrame({
    required this.step,
    required this.onBack,
    required this.onSkip,
    required this.body,
    super.key,
  });

  /// The step being shown; decides whether the top "Skip for now" link
  /// appears.
  final OnboardingStep step;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called when the "Skip for now" link is pressed.
  final VoidCallback onSkip;

  /// The layout-specific content below the header.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: '',
      // Always shown, even on the first step — the mockups draw the same
      // back chevron (and an active bottom "Back" button) on every step,
      // including Profile; `OnboardingController.back` is already a safe
      // no-op there.
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      trailing: step.skip == OnboardingSkipAffordance.topLink
          ? AppTextLinkButton(label: t.onboarding.skipForNow, onPressed: onSkip)
          : null,
      contentWidth: AppContentWidth.auth,
      edgePadding: space6,
      scrollable: false,
      body: body,
    );
  }
}
