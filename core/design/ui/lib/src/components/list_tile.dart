import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/internal/text_styles.dart';
import 'package:ui/src/layout/app_gap.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// The minimum logical-pixel hit target on a tappable [AppListTile].
const double _minHitTarget = 48;

/// A headless, mix-styled list row with leading/title/subtitle/trailing
/// slots, optionally tappable.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppListTile extends StatelessWidget {
  /// Creates an `AppListTile`.
  ///
  /// When [onTap] is set, [title] (and [subtitle], if present) become this
  /// tile's accessible name and hint — no separate `semanticLabel`
  /// parameter is needed.
  const AppListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// The tile's primary text.
  final String title;

  /// Secondary text shown below [title].
  final String? subtitle;

  /// Content shown before the title/subtitle column, e.g. an icon.
  final Widget? leading;

  /// Content shown after the title/subtitle column, e.g. a chevron.
  final Widget? trailing;

  /// Called when the tile is tapped. `null` renders a non-interactive row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    final row = _AppListTileRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
    );

    if (tap == null) {
      return Box(style: _staticTileStyle(), child: row);
    }

    return NakedButton(
      onPressed: tap,
      semanticLabel: title,
      semanticHint: subtitle,
      child: row,
      builder: (_, state, child) => WidgetStateProvider(
        states: state.states,
        child: Box(style: _interactiveTileStyle(), child: child),
      ),
    );
  }
}

/// The leading/title/subtitle/trailing layout, shared by the tappable and
/// non-tappable rendering paths.
class _AppListTileRow extends StatelessWidget {
  const _AppListTileRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final leadingContent = leading;
    final trailingContent = trailing;
    final subtitleText = subtitle;

    return Row(
      children: [
        if (leadingContent != null) ...[leadingContent, const AppGap.h3()],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledText(title, style: _titleStyle()),
              if (subtitleText != null)
                Box(
                  style: BoxStyler().paddingTop(space1()),
                  child: StyledText(subtitleText, style: secondaryTextStyle()),
                ),
            ],
          ),
        ),
        if (trailingContent != null) ...[const AppGap.h3(), trailingContent],
      ],
    );
  }
}

/// The base padding and minimum-height every tile, tappable or not, shares.
BoxStyler _baseTileStyle() {
  return BoxStyler()
      .paddingX(space4())
      .paddingY(space3())
      .minHeight(_minHitTarget);
}

/// Styling for a non-interactive tile: no hover, press, or focus treatment.
BoxStyler _staticTileStyle() => _baseTileStyle();

/// Styling for a tappable tile's fill and focus-ring across interaction
/// states.
BoxStyler _interactiveTileStyle() {
  return _baseTileStyle()
      .onHovered(BoxStyler().color(colorBgSubtle()))
      .onPressed(BoxStyler().color(colorAccentTint()))
      .onFocused(
        BoxStyler().borderAll(color: colorFocusRing(), width: strokeStrong()),
      );
}

/// The title's typography, composed from `product*` scale tokens per this
/// package's convention (there is no pre-built body-text token).
TextStyler _titleStyle() {
  return TextStyler()
      .fontSize(productBody())
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorFg());
}
