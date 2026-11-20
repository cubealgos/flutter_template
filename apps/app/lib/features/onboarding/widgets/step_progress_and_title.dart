import 'package:app/features/onboarding/widgets/step_dot.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// "Step X of N" + dots progress, then the step's `h1` title, centered —
/// matches every `Onboarding*` mockup's header block (minus its back/skip
/// row, which `AppScreenHeader` already renders).
class StepProgressAndTitle extends StatelessWidget {
  /// Creates the block.
  const StepProgressAndTitle({
    required this.index,
    required this.total,
    required this.title,
    super.key,
  });

  /// The zero-based index of the current step.
  final int index;

  /// The total number of steps.
  final int total;

  /// The current step's title.
  final String title;

  @override
  Widget build(BuildContext context) {
    final label = t.onboarding.stepProgress(current: index + 1, total: total);

    return Column(
      children: [
        StyledText(
          label.toUpperCase(),
          style: eyebrowStyle().textAlign(TextAlign.center),
        ),
        const AppGap.v2(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const AppGap.h2(),
              StepDot(active: i == index),
            ],
          ],
        ),
        const AppGap.v6(),
        StyledText(title, style: h1Style().textAlign(TextAlign.center)),
      ],
    );
  }
}
