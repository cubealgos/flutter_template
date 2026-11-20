import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The small checkmark-plus-"Saved" hint the Profile and Preferences step
/// mockups show under a field once its answer has actually been recorded
/// — never shown for an answer that only has a visual default (e.g. the
/// Preferences step's pre-selected "Personal use" option before the user
/// has touched it).
class OnboardingSavedHint extends StatelessWidget {
  /// Creates the hint. Rendered invisible-but-space-reserving when
  /// [visible] is `false`, so a step's layout doesn't jump the moment an
  /// answer is first saved.
  const OnboardingSavedHint({required this.visible, super.key});

  /// Whether to actually show the hint.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledText('✓', style: captionStyle().color(colorSuccess())),
          // No token matches the mockup's 6px gap exactly (space1=4,
          // space2=8) — space1 ("icon padding, tight inline gaps") fits
          // this icon+text pairing's role most closely.
          const AppGap.h1(),
          StyledText(t.onboarding.savedHint, style: captionStyle()),
        ],
      ),
    );
  }
}
