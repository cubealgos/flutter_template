import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/tokens.g.dart';

/// The minimum logical-pixel hit target on [DismissCloseButton].
const double _minHitTarget = 48;

/// A small, always-visible close affordance with its own accessible name,
/// shared by `AppDialog` and `AppSheet` — the built-in dismiss control on
/// either one never relies on the caller's content to provide an
/// accessible name of its own.
///
/// Pops the nearest [Navigator] when activated.
class DismissCloseButton extends StatelessWidget {
  /// Creates a `DismissCloseButton`.
  const DismissCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: NakedButton(
        onPressed: () => Navigator.of(context).maybePop(),
        semanticLabel: 'Close',
        builder: (_, state, _) => WidgetStateProvider(
          states: state.states,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minHitTarget,
              minHeight: _minHitTarget,
            ),
            child: Center(child: StyledText('×', style: _closeGlyphStyle())),
          ),
        ),
      ),
    );
  }
}

/// The close glyph's typography, including a visible focus-ring color
/// swap since this control has no border to grow on focus.
TextStyler _closeGlyphStyle() {
  return TextStyler()
      .fontSize(productH2())
      .color(colorFgSubtle())
      .onHovered(TextStyler().color(colorFg()))
      .onFocused(TextStyler().color(colorFocusRing()));
}
