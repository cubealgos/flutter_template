import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/layout/app_gap.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

/// The chip's dot indicator size, in logical pixels — matches the
/// mockups' `.chip-dot` (`width: 8px; height: 8px`).
const double _dotSize = 8;

/// An `eyebrow`-styled status indicator: a colored dot plus an
/// upper-cased label, bordered to match its tone.
///
/// Built for consent status ("Accepted"/"Rejected"/"Not set", spec.md
/// §2.11) and any other done/not-done or accepted/rejected state a
/// screen needs to show at a glance rather than as a sentence.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppStatusChip extends StatelessWidget {
  /// Creates an `AppStatusChip`.
  const AppStatusChip({
    required this.label,
    super.key,
    this.tone = AppStatusTone.neutral,
  });

  /// The chip's visible text. Rendered upper-cased regardless of the
  /// casing passed in — this is a finished, self-contained chip (unlike
  /// `eyebrowStyle()`, which leaves upper-casing to the caller).
  final String label;

  /// The chip's semantic tone, driving its border, dot, and text color.
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colorToken = _toneColor(tone);

    return Box(
      style: BoxStyler()
          .paddingX(space3())
          .paddingY(space2())
          .borderAll(color: colorToken(), width: strokeThin()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Box(
            style: BoxStyler()
                .size(_dotSize, _dotSize)
                .borderRadiusAll(radiusFull())
                .color(colorToken()),
          ),
          const AppGap.h2(),
          StyledText(
            label.toUpperCase(),
            style: eyebrowStyle().color(colorToken()),
          ),
        ],
      ),
    );
  }
}

/// The tone an [AppStatusChip] communicates.
enum AppStatusTone {
  /// A default/inactive state — "Not set" (spec.md §2.11).
  neutral,

  /// A positive/accepted state — "Accepted".
  success,

  /// A negative/rejected state — "Rejected".
  danger,

  /// A state that needs attention but hasn't failed.
  warning,
}

/// The token driving [tone]'s border, dot, and text color.
ColorToken _toneColor(AppStatusTone tone) {
  return switch (tone) {
    AppStatusTone.neutral => colorFgSubtle,
    AppStatusTone.success => colorSuccess,
    AppStatusTone.danger => colorDanger,
    AppStatusTone.warning => colorWarning,
  };
}
