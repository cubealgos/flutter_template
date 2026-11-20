import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/internal/spinner.dart';
import 'package:ui/src/tokens.g.dart';

/// The minimum logical-pixel hit target on every tappable [AppButton].
const double _minHitTarget = 48;

/// A headless, mix-styled button with built-in loading, disabled, and
/// accessible-name handling.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppButton extends StatelessWidget {
  /// Creates an `AppButton`.
  ///
  /// [semanticLabel] is required even when [child] already renders visible
  /// text: naked_ui's accessible-name plumbing reads only this parameter,
  /// never the visible [child] subtree.
  const AppButton({
    required this.child,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.disabled = false,
  });

  /// The button's visible content, typically a [StyledText].
  final Widget child;

  /// The accessible name announced to assistive technology.
  final String semanticLabel;

  /// Called when the button is activated. `null` renders the button inert.
  final VoidCallback? onPressed;

  /// The visual emphasis of this button.
  final AppButtonVariant variant;

  /// Shows a spinner and blocks interaction while `true`.
  final bool loading;

  /// Forces the button inert regardless of [onPressed].
  final bool disabled;

  bool get _isInteractive => !disabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundToken(
      variant,
      interactive: _isInteractive,
    ).resolve(context);
    // The label inherits the variant's foreground colour, following the same
    // interactive state as the box. Without this a plain `Text` (or a
    // `StyledText` with no colour of its own) falls back to the ambient
    // default, black: invisible on secondary in dark mode and below contrast
    // on the filled variants.
    final content = loading
        ? Spinner(
            color: foreground,
            period: motionDurationStep.resolve(context),
          )
        : DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: child,
          );

    return NakedButton(
      onPressed: _isInteractive ? onPressed : null,
      enabled: _isInteractive,
      semanticLabel: semanticLabel,
      child: content,
      builder: (_, state, child) => WidgetStateProvider(
        states: state.states,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minHitTarget,
            minHeight: _minHitTarget,
          ),
          child: Box(
            style: _styleFor(variant),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Visual emphasis levels for [AppButton].
enum AppButtonVariant {
  /// The single primary call to action on a surface.
  primary,

  /// A lower-emphasis action alongside a primary one.
  secondary,

  /// An irreversible or destructive action.
  destructive,

  /// A page-level trigger for an irreversible or destructive action, one
  /// step removed from its own confirmation — outlined rather than filled,
  /// so only the confirmation dialog's actual destructive action reads as
  /// filled. E.g. Account Settings' "Delete account", which opens a
  /// confirmation dialog whose own "Delete" stays [destructive] (filled).
  destructiveOutlined,
}

/// The shared padding, corner radius, and focus-ring treatment every
/// [AppButtonVariant] builds on.
BoxStyler _baseButtonStyle() {
  return BoxStyler()
      .paddingX(space4())
      .paddingY(space3())
      .borderRadiusAll(radiusMd())
      .onFocused(
        BoxStyler().borderAll(color: colorFocusRing(), width: strokeStrong()),
      );
}

/// The fill, border, and interaction-state styling for [variant].
BoxStyler _styleFor(AppButtonVariant variant) {
  final base = _baseButtonStyle();

  return switch (variant) {
    AppButtonVariant.primary =>
      base
          .color(colorAccent())
          .onHovered(
            BoxStyler().borderAll(color: colorOnAccent(), width: strokeThin()),
          )
          .onDisabled(BoxStyler().color(colorDisabled())),
    AppButtonVariant.secondary =>
      base
          .color(colorBgSubtle())
          .borderAll(color: colorBorder(), width: strokeDefault())
          .onHovered(BoxStyler().color(colorAccentTint()))
          .onDisabled(
            BoxStyler()
                .color(colorBgSubtle())
                .borderAll(color: colorDisabled(), width: strokeDefault()),
          ),
    AppButtonVariant.destructive =>
      base
          .color(colorDanger())
          .onHovered(
            BoxStyler().borderAll(color: colorOnAccent(), width: strokeThin()),
          )
          .onDisabled(BoxStyler().color(colorDisabled())),
    AppButtonVariant.destructiveOutlined =>
      base
          .borderAll(color: colorDanger(), width: strokeDefault())
          .onHovered(BoxStyler().color(colorBgSubtle()))
          .onDisabled(
            BoxStyler().borderAll(
              color: colorDisabled(),
              width: strokeDefault(),
            ),
          ),
  };
}

/// The token for [variant]'s content (text/icon/spinner) color. An inert
/// secondary or destructiveOutlined button matches its `colorDisabled`
/// border; the filled variants keep `colorOnAccent`, which stays legible on
/// their `colorDisabled` fill.
ColorToken _foregroundToken(
  AppButtonVariant variant, {
  required bool interactive,
}) {
  return switch (variant) {
    AppButtonVariant.primary => colorOnAccent,
    AppButtonVariant.secondary => interactive ? colorFg : colorDisabled,
    AppButtonVariant.destructive => colorOnAccent,
    AppButtonVariant.destructiveOutlined =>
      interactive ? colorDanger : colorDisabled,
  };
}
