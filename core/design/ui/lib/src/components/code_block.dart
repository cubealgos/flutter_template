import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

/// A scrollable, monospace, bordered container for verbatim data — the
/// exported-data JSON result in Privacy Settings (spec.md §2.11), which
/// currently renders as plain wrapped proportional-body text with no
/// container, no monospace font, and no scroll region at all.
///
/// Uses `monoDataStyle()` (spec §1.2's `mono-data` role, 16px), not the
/// mockups' own ad hoc 13px — the spec explicitly assigns "exported JSON
/// block" to the named `mono-data` scale role, so this reuses that shared
/// token rather than a one-off size found only in the mockup markup.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppCodeBlock extends StatelessWidget {
  /// Creates an `AppCodeBlock`.
  const AppCodeBlock({required this.text, super.key, this.maxHeight});

  /// The verbatim text shown inside the block.
  final String text;

  /// Caps the block's height and makes it vertically scrollable beyond
  /// that. `null` (the default) lets the block grow with its content.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final cap = maxHeight;
    final content = SingleChildScrollView(
      child: StyledText(text, style: monoDataStyle()),
    );

    return Box(
      style: BoxStyler()
          .color(colorSurface())
          .borderAll(color: colorBorder(), width: strokeThin())
          .paddingAll(space4()),
      child: cap == null
          ? content
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: cap),
              child: content,
            ),
    );
  }
}
