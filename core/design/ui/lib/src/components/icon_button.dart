import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/tokens.g.dart';

/// The fixed square size of every [AppIconButton] — its hit target, not
/// just its glyph. Matches the mockups' `.btn-icon` (`width: 44px; height:
/// 44px`) and this package's existing `_minHitTarget` convention.
const double _size = 48;

/// An icon-only variant of tappable chrome: a plain, unbordered 48×48
/// square with hover/focus/disabled states, sized and colored by the
/// design tokens.
///
/// `AppButton` supports an icon-only *use* (pass a small [icon] as its
/// `child`), but its padding and border are tuned for a text label, not a
/// bare glyph — this is the dedicated icon-button chrome the mockups'
/// `.btn-icon` class describes (transparent fill and border at rest, a
/// subtle fill on hover, the same focus ring as every other control). Used
/// by `AppScreenHeader`'s back button; also fits a header's trailing
/// icon-only action (e.g. Home's "Settings" affordance).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppIconButton extends StatelessWidget {
  /// Creates an `AppIconButton`.
  ///
  /// [semanticLabel] is required even when [icon] is purely decorative —
  /// naked_ui's accessible-name plumbing reads only this parameter, never
  /// any semantics [icon] itself might carry.
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
    this.disabled = false,
  });

  /// The glyph shown inside the button, e.g. an `AppChevronIcon`.
  final Widget icon;

  /// The accessible name announced to assistive technology.
  final String semanticLabel;

  /// Called when the button is activated. `null` renders the button
  /// inert.
  final VoidCallback? onPressed;

  /// Forces the button inert regardless of [onPressed].
  final bool disabled;

  bool get _isInteractive => !disabled && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: _isInteractive ? onPressed : null,
      enabled: _isInteractive,
      semanticLabel: semanticLabel,
      child: icon,
      builder: (_, state, child) => WidgetStateProvider(
        states: state.states,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _size, minHeight: _size),
          child: Box(
            style: _style(),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// The button's fill and interaction-state styling — no border at rest,
/// matching the mockups' `.btn-icon` (`border: 1px solid transparent`).
BoxStyler _style() {
  return BoxStyler()
      .onHovered(BoxStyler().color(colorBgSubtle()))
      .onFocused(
        BoxStyler().borderAll(color: colorFocusRing(), width: strokeStrong()),
      )
      .onDisabled(BoxStyler().color(colorBgSubtle()));
}
