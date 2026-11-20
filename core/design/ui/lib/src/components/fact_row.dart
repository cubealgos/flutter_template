import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/layout/app_gap.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';
import 'package:ui/src/typography/text_styles.dart';

/// `fact-label`'s font size — 12px, matching the mockups' `.fact-label`
/// (`font: 600 12px/1.4`). One size off the named scale's `caption` role
/// in isolation (`captionStyle()` is 12px/400/muted, not upper-cased or
/// tracked) — this composes the same `productCaption` size token with its
/// own weight/transform/tracking rather than introducing a new size
/// token, since no scale role in spec.md §1.2 names this exact
/// combination.
const FontWeight _labelWeight = FontWeight.w600;

/// `fact-label`'s line-height, matching the mockups (`font: 600 12px/1.4`).
const double _labelLineHeight = 1.4;

/// [productCaption]'s own font size, in logical pixels — see
/// `text_styles.dart`'s `_eyebrowFontSizePx` for why this is duplicated as
/// a literal rather than resolved from the token at const-evaluation
/// time. Keep in sync with `tokens/typography.json`'s `product.caption`
/// value.
const double _labelFontSizePx = 12;

/// `letter-spacing: 0.04em`, matching the mockups' `.fact-label`.
const double _trackingEm = 0.04;

/// `fact-label`'s tracking, matching the mockups — same basis as
/// `eyebrowStyle()`'s, pre-multiplied against [_labelFontSizePx].
const double _labelLetterSpacing = _labelFontSizePx * _trackingEm;

/// A label/value definition row — company facts on the Legal Document
/// screen (spec.md §2.9), where the current code renders one interpolated
/// `"${label}: ${value}"` string per row with no visual separation
/// between a scanning reader's label column and its value.
///
/// [isFirst] draws a top hairline in addition to the row's own bottom
/// hairline, matching the mockups' `.fact-row:first-child` rule — pass
/// `true` for the first row in a list of facts so the list reads as one
/// bounded block, not `true` for every row (which would double the rule
/// between adjacent rows).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppFactRow extends StatelessWidget {
  /// Creates an `AppFactRow`.
  const AppFactRow({
    required this.label,
    required this.value,
    super.key,
    this.isFirst = false,
  });

  /// The subordinate label, e.g. "VAT ID". Rendered upper-cased.
  final String label;

  /// The primary value, e.g. "DE000000000".
  final String value;

  /// Whether to also draw a top hairline (see class dartdoc).
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    var style = BoxStyler()
        .paddingY(space3())
        .borderBottom(color: colorBorder(), width: strokeThin());

    if (isFirst) {
      style = style.borderTop(color: colorBorder(), width: strokeThin());
    }

    return Box(
      style: style,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledText(label.toUpperCase(), style: _labelStyle()),
          const AppGap.v1(),
          StyledText(value, style: bodyStyle()),
        ],
      ),
    );
  }
}

/// `fact-label`'s typography: `productCaption`'s size, upper-cased and
/// tracked like `eyebrowStyle()` but at `caption`'s smaller size and
/// weight-600 rather than `eyebrow`'s own 14px.
TextStyler _labelStyle() {
  return TextStyler()
      .fontSize(productCaption())
      .height(_labelLineHeight)
      .fontWeight(_labelWeight)
      .letterSpacing(_labelLetterSpacing)
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorFgSubtle());
}
