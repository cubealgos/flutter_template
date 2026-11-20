import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// Wraps [child] in a `MixScope` configured from the generated design
/// tokens (`lib/src/tokens.g.dart`), picking [lightTokens] or [darkTokens]
/// by platform brightness.
///
/// By default the brightness comes from `MediaQuery.platformBrightness`, so
/// this widget must sit under a `MediaQuery` (any real app has one; widget
/// tests that don't can supply [brightnessOverride] instead of wrapping one
/// in). Pass [brightnessOverride] to pin a brightness regardless of the
/// platform — e.g. a manual light/dark toggle in `Settings`.
///
/// Every component in this package resolves its styling against this
/// scope; wrap the whole app in exactly one `AppTheme`, as high as
/// possible in the widget tree (the app wires this in at the
/// app root).
class AppTheme extends StatelessWidget {
  /// Creates an `AppTheme`.
  const AppTheme({required this.child, super.key, this.brightnessOverride});

  /// The subtree to theme.
  final Widget child;

  /// Forces light or dark regardless of the platform brightness. `null`
  /// (the default) follows `MediaQuery.platformBrightness`.
  final Brightness? brightnessOverride;

  @override
  Widget build(BuildContext context) {
    final brightness =
        brightnessOverride ?? MediaQuery.platformBrightnessOf(context);
    final values = brightness == Brightness.dark ? darkTokens : lightTokens;

    return MixScope(
      colors: values.colors,
      spaces: values.spaces,
      radii: values.radii,
      doubles: values.doubles,
      textStyles: values.textStyles,
      fontWeights: values.fontWeights,
      tokens: values.tokens,
      // A plain `Text` (or a `StyledText` that never chains `.fontFamily(...)`
      // of its own — `AppButton`'s label, styled only via
      // `DefaultTextStyle.merge` for its colour) inherits nothing from
      // `MixScope` and otherwise falls back to Flutter's platform default
      // (Roboto), not this package's bundled body font. Body role
      // (size + colour) so it reads as ordinary text, not any specific
      // component's own styling.
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: packageFontFamily(fontFamilyBody),
          fontFamilyFallback: fontFamilyBodyFallback,
          fontSize: values.doubles[productBody],
          color: values.colors[colorFg],
        ),
        child: child,
      ),
    );
  }
}
