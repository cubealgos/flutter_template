import 'package:app/features/home/home_model.dart';
import 'package:app/features/home/widgets/setup_card_row.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The "Finish your setup" card: title + "N of total done", a dismiss
/// control, and one row per still-open step linking back into onboarding.
class SetupCard extends StatelessWidget {
  /// Creates the card.
  const SetupCard({
    required this.completedStepCount,
    required this.totalStepCount,
    required this.openSteps,
    required this.onDismiss,
    required this.onOpenOnboarding,
    super.key,
  });

  // The dismiss "×" is a plain glyph, not spacing — same convention as
  // `core/design/ui`'s own `DismissCloseButton`.
  static const double _dismissGlyphSize = 16;

  /// How many onboarding steps are already done.
  final int completedStepCount;

  /// The total number of onboarding steps.
  final int totalStepCount;

  /// The onboarding steps that are still open, one row each.
  final List<HomeSetupItem> openSteps;

  /// Called when the dismiss control is pressed.
  final VoidCallback onDismiss;

  /// Called when an open step's row is tapped.
  final VoidCallback onOpenOnboarding;

  @override
  Widget build(BuildContext context) {
    final progress = t.home.setupCardProgress(
      completed: completedStepCount,
      total: totalStepCount,
    );

    return Box(
      // No token matches the mockup's 20px card padding exactly (space4=16,
      // space6=24, equidistant) — kept the nearest, space4.
      style: BoxStyler()
          .color(colorSurface())
          .borderAll(color: colorBorder(), width: strokeThin())
          .paddingAll(space4()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StyledText(t.home.setupCardTitle, style: h3Style()),
                    StyledText(progress, style: captionStyle()),
                  ],
                ),
              ),
              AppIconButton(
                icon: StyledText(
                  '×',
                  style: TextStyler()
                      .fontSize(_dismissGlyphSize)
                      .color(colorFg()),
                ),
                semanticLabel: t.home.setupCardDismiss,
                onPressed: onDismiss,
              ),
            ],
          ),
          const AppGap.v3(),
          for (final entry in openSteps.indexed)
            SetupCardRow(
              title: entry.$2.title,
              showTopBorder: entry.$1 > 0,
              onTap: onOpenOnboarding,
            ),
        ],
      ),
    );
  }
}
