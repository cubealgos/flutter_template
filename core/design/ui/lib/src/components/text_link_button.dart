import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

/// The minimum logical-pixel hit target on an [AppTextLinkButton], even
/// though its visible text is smaller — same 48px convention as every
/// other tappable control in this package.
const double _minHitTarget = 48;

/// An inline, underlined text button for a subordinate action that must
/// not read as a third bordered button next to a screen's real actions —
/// "Manage in Settings" below the consent buttons, "Use a different
/// email"/"Resend code" below the sign-in code field, and the Legal/
/// Terms/Privacy footer links on sign-in and the paywall stub (spec.md
/// §2.2, §2.3, §2.13; §3's Pattern-B-adjacent complaint that every one of
/// these is currently a full bordered `AppButtonVariant.secondary`
/// button).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppTextLinkButton extends StatelessWidget {
  /// Creates an `AppTextLinkButton`.
  const AppTextLinkButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.semanticLabel,
  });

  /// The button's visible, underlined text.
  final String label;

  /// The accessible name, if it should differ from [label].
  final String? semanticLabel;

  /// Called when the button is activated.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NakedButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      child: StyledText(label, style: _style()),
      builder: (_, state, child) => WidgetStateProvider(
        states: state.states,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHitTarget),
          // `widthFactor: 1` shrink-wraps the label horizontally; a plain
          // `Center` fills the available width, one link per `Wrap` line.
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// The link text's typography — matches the mockups' `.btn-link` (`font:
/// 600 14px`, underlined, `--signal-light`/[colorLink]).
TextStyler _style() {
  return TextStyler()
      .fontSize(productBodySm())
      .fontWeight(FontWeight.w600)
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorLink())
      .decoration(TextDecoration.underline);
}
