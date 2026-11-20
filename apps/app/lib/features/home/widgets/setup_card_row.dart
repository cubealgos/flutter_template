import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/ui.dart';

/// One still-open onboarding step in the setup card: its title and a
/// trailing chevron, tappable to jump back into onboarding.
class SetupCardRow extends StatelessWidget {
  /// Creates the row.
  const SetupCardRow({
    required this.title,
    required this.showTopBorder,
    required this.onTap,
    super.key,
  });

  /// The step's title.
  final String title;

  /// Whether to draw a divider above the row (every row but the first).
  final bool showTopBorder;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // No token matches the mockup's 10px vertical padding exactly
    // (space2=8, space3=12, equidistant) — kept the nearest, space2.
    var style = BoxStyler().paddingY(space2());
    if (showTopBorder) {
      style = style.borderTop(color: colorBorder(), width: strokeThin());
    }

    return NakedButton(
      onPressed: onTap,
      semanticLabel: title,
      builder: (_, _, child) => Box(style: style, child: child),
      child: Row(
        children: [
          Expanded(child: StyledText(title, style: bodySmStyle())),
          const AppChevronIcon(
            direction: AppChevronDirection.end,
            color: colorFgSubtle,
          ),
        ],
      ),
    );
  }
}
