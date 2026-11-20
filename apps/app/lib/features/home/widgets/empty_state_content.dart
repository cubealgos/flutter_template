import 'package:app/features/home/widgets/tray_glyph.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// Home's empty state: a tray glyph above a centered, muted message.
class EmptyStateContent extends StatelessWidget {
  /// Creates the empty state.
  const EmptyStateContent({super.key});

  // No space/size token is anywhere near a 280px reading measure — kept
  // as a plain literal.
  static const double _maxMessageWidth = 280;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TrayGlyph(),
        const AppGap.v4(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxMessageWidth),
          child: StyledText(
            t.home.emptyStateMessage,
            style: bodyStyle()
                .color(colorFgSubtle())
                .textAlign(TextAlign.center),
          ),
        ),
      ],
    );
  }
}
