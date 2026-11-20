import 'package:app/features/home/home_model.dart';
import 'package:app/features/home/widgets/empty_state_content.dart';
import 'package:app/features/home/widgets/home_screen_frame.dart';
import 'package:app/features/home/widgets/home_setup_card.dart';
import 'package:app/features/home/widgets/home_sign_out_button.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Home below the tablet breakpoint; matches `Home-phone-dark.dc.html`: a
/// top-anchored card and a bottom-pinned button either side of a flexible,
/// centered empty state.
class HomeMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const HomeMobileLayout({
    required this.showSetupCard,
    required this.completedStepCount,
    required this.totalStepCount,
    required this.openSteps,
    required this.onDismissSetupCard,
    required this.onOpenOnboarding,
    required this.onSignOut,
    required this.onOpenSettings,
    super.key,
  });

  /// Whether the "Finish your setup" card is shown.
  final bool showSetupCard;

  /// How many onboarding steps are already done.
  final int completedStepCount;

  /// The total number of onboarding steps.
  final int totalStepCount;

  /// The onboarding steps that are still open.
  final List<HomeSetupItem> openSteps;

  /// Called when the setup card is dismissed.
  final VoidCallback onDismissSetupCard;

  /// Called when an open step in the setup card is tapped.
  final VoidCallback onOpenOnboarding;

  /// Called when the sign-out button is pressed.
  final VoidCallback onSignOut;

  /// Called when the header's settings button is pressed.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return HomeScreenFrame(
      onOpenSettings: onOpenSettings,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSetupCard) ...[
            HomeSetupCard(
              completedStepCount: completedStepCount,
              totalStepCount: totalStepCount,
              openSteps: openSteps,
              onDismiss: onDismissSetupCard,
              onOpenOnboarding: onOpenOnboarding,
            ),
            const AppGap.v4(),
          ],
          const Expanded(child: Center(child: EmptyStateContent())),
          const AppGap.v4(),
          HomeSignOutButton(onSignOut: onSignOut),
        ],
      ),
    );
  }
}
