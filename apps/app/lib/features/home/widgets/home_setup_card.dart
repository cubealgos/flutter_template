import 'package:app/features/home/home_model.dart';
import 'package:app/features/home/widgets/narrow_column.dart';
import 'package:app/features/home/widgets/setup_card.dart';
import 'package:flutter/widgets.dart';

/// The "Finish your setup" card in Home's narrow, dialog-weight column —
/// the same in every layout.
class HomeSetupCard extends StatelessWidget {
  /// Creates the card.
  const HomeSetupCard({
    required this.completedStepCount,
    required this.totalStepCount,
    required this.openSteps,
    required this.onDismiss,
    required this.onOpenOnboarding,
    super.key,
  });

  /// How many onboarding steps are already done.
  final int completedStepCount;

  /// The total number of onboarding steps.
  final int totalStepCount;

  /// The onboarding steps that are still open.
  final List<HomeSetupItem> openSteps;

  /// Called when the card is dismissed.
  final VoidCallback onDismiss;

  /// Called when an open step in the card is tapped.
  final VoidCallback onOpenOnboarding;

  @override
  Widget build(BuildContext context) {
    return NarrowColumn(
      child: SetupCard(
        completedStepCount: completedStepCount,
        totalStepCount: totalStepCount,
        openSteps: openSteps,
        onDismiss: onDismiss,
        onOpenOnboarding: onOpenOnboarding,
      ),
    );
  }
}
