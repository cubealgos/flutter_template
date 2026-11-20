import 'package:app/features/home/home_model.dart';
import 'package:app/features/home/widgets/empty_state_content.dart';
import 'package:app/features/home/widgets/home_screen_frame.dart';
import 'package:app/features/home/widgets/home_setup_card.dart';
import 'package:app/features/home/widgets/home_sign_out_button.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Home from the desktop breakpoint; matches `Home-desktop-dark.dc.html`:
/// the card, empty state and sign-out button sit in one group, vertically
/// centered as a whole.
class HomeDesktopLayout extends StatelessWidget {
  /// Creates the layout.
  const HomeDesktopLayout({
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
      // The group is centered within the body's `maxHeight`, so the body's
      // own constraints are needed here (the breakpoint itself is
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
                  if (showSetupCard) ...[
                    HomeSetupCard(
                      completedStepCount: completedStepCount,
                      totalStepCount: totalStepCount,
                      openSteps: openSteps,
                      onDismiss: onDismissSetupCard,
                      onOpenOnboarding: onOpenOnboarding,
                    ),
                    const AppGap.v8(),
                  ],
                  const EmptyStateContent(),
                  const AppGap.v8(),
                  HomeSignOutButton(onSignOut: onSignOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
