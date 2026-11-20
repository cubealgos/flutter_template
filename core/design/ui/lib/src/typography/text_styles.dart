import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/package_font_family.dart';

// Font weight is documented in `tokens/typography.json`'s `$description`
// prose (see `product.*`'s per-role comments), but is not itself a
// generated token — `tokens.g.dart`'s `_fontWeights` map is empty, and no
// existing component in this package resolves weight from a token either
// (every `TextStyler` chain below is the first to set `fontWeight` at
// all). These constants are this file's own literal record of app-design
// spec §1.2's per-role weight and line-height columns, the same way
// `_minHitTarget`-style constants elsewhere in this package hold a spec
// value that isn't itself tokenized.

/// Weight for [displayStyle], [h1Style] and [h2Style] — spec §1.2.
const FontWeight _weightBold = FontWeight.w700;

/// Weight for [h3Style], [eyebrowStyle] and [buttonStyle] — spec §1.2.
const FontWeight _weightSemibold = FontWeight.w600;

/// Weight for [bodyStyle], [bodySmStyle], [captionStyle] and
/// [monoDataStyle] — spec §1.2.
const FontWeight _weightRegular = FontWeight.w400;

/// Line-height for [displayStyle] — spec §1.2.
const double _lineHeightDisplay = 1.1;

/// Line-height for [h1Style] — spec §1.2.
const double _lineHeightH1 = 1.2;

/// Line-height for [h2Style] — spec §1.2.
const double _lineHeightH2 = 1.3;

/// Line-height for [h3Style] — spec §1.2.
const double _lineHeightH3 = 1.3;

/// Line-height for [bodyStyle] — spec §1.2.
const double _lineHeightBody = 1.6;

/// Line-height for [bodySmStyle] — spec §1.2.
const double _lineHeightBodySm = 1.5;

/// Line-height for [captionStyle] — spec §1.2.
const double _lineHeightCaption = 1.5;

/// Line-height for [eyebrowStyle] — spec §1.2.
const double _lineHeightEyebrow = 1.4;

/// Line-height for [monoDataStyle] — spec §1.2.
const double _lineHeightMonoData = 1.4;

/// Line-height for [buttonStyle] — spec §1.2.
const double _lineHeightButton = 1;

/// [productEyebrow]'s own font size, in logical pixels — duplicated here
/// (rather than resolved from the token at const-evaluation time, which
/// [TextStyler]'s tokens don't support) purely to make
/// [_eyebrowLetterSpacing]'s derivation legible; keep in sync with
/// `tokens/typography.json`'s `product.eyebrow` value.
const double _eyebrowFontSizePx = 14;

/// `letter-spacing: 0.04em`, spec §1.2's `eyebrow` tracking.
const double _trackingEm = 0.04;

/// `eyebrow`'s tracking. [TextStyle.letterSpacing] is absolute logical
/// pixels, not font-relative `em`, so this pre-multiplies [_trackingEm]
/// against [_eyebrowFontSizePx] — see the correction note in `spec.md`
/// §1.2 for why this role isn't `fontFamilyMono` despite being tracked
/// like a data role.
const double _eyebrowLetterSpacing = _eyebrowFontSizePx * _trackingEm;

/// The `display` role (32px/1.1, Host Grotesk 700): spec §1.2's paywall
/// price size — "the one place a number should dominate". Not used for
/// screen titles; see [h1Style].
TextStyler displayStyle() {
  return TextStyler()
      .fontSize(productDisplay())
      .height(_lineHeightDisplay)
      .fontWeight(_weightBold)
      .fontFamily(packageFontFamily(fontFamilyTitle))
      .fontFamilyFallback(fontFamilyTitleFallback)
      .color(colorInk());
}

/// The `h1` role (24px/1.2, Host Grotesk 700): one screen title, top of
/// content — spec §1.2.
TextStyler h1Style() {
  return TextStyler()
      .fontSize(productH1())
      .height(_lineHeightH1)
      .fontWeight(_weightBold)
      .fontFamily(packageFontFamily(fontFamilyTitle))
      .fontFamilyFallback(fontFamilyTitleFallback)
      .color(colorInk());
}

/// The `h2` role (20px/1.3, Host Grotesk 700): a section heading within a
/// screen — spec §1.2.
TextStyler h2Style() {
  return TextStyler()
      .fontSize(productH2())
      .height(_lineHeightH2)
      .fontWeight(_weightBold)
      .fontFamily(packageFontFamily(fontFamilyTitle))
      .fontFamilyFallback(fontFamilyTitleFallback)
      .color(colorInk());
}

/// The `h3` role (16px/1.3, Host Grotesk 600): a card/group or dialog title
/// — spec §1.2.
TextStyler h3Style() {
  return TextStyler()
      .fontSize(productH3())
      .height(_lineHeightH3)
      .fontWeight(_weightSemibold)
      .fontFamily(packageFontFamily(fontFamilyTitle))
      .fontFamilyFallback(fontFamilyTitleFallback)
      .color(colorInk());
}

/// The `body` role (16px/1.6, Host Grotesk 400): default paragraph/list
/// text — spec §1.2. 16px is the floor, not a stylistic choice: below it,
/// Safari/iOS auto-zooms a focused form input.
TextStyler bodyStyle() {
  return TextStyler()
      .fontSize(productBody())
      .height(_lineHeightBody)
      .fontWeight(_weightRegular)
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorInk());
}

/// The `body-sm` role (14px/1.5, Host Grotesk 400): secondary text, list
/// subtitles, helper text — spec §1.2. Resolves to [colorInk]; for the
/// muted variant used by field labels and list subtitles, see this
/// package's internal `secondaryTextStyle()`.
TextStyler bodySmStyle() {
  return TextStyler()
      .fontSize(productBodySm())
      .height(_lineHeightBodySm)
      .fontWeight(_weightRegular)
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorInk());
}

/// The `caption` role (12px/1.5, Host Grotesk 400, muted): fine print,
/// legal footnotes, timestamps — spec §1.2.
TextStyler captionStyle() {
  return TextStyler()
      .fontSize(productCaption())
      .height(_lineHeightCaption)
      .fontWeight(_weightRegular)
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorFgSubtle());
}

/// The `eyebrow` role (14px/1.4, Host Grotesk 600, muted by default,
/// tracked 0.04em): section labels, status tags — spec §1.2's
/// 2026-09-25 correction (Host Grotesk, **not** IBM Plex Mono).
///
/// This helper does not upper-case a [Text]'s content — unlike CSS, a
/// [TextStyle] cannot apply a `text-transform`, so callers must upper-case
/// the string themselves (`label.toUpperCase()`) before rendering it with
/// this style. Chain `.color(...)` on the returned [TextStyler] for the
/// signal-colored variant (`t-eyebrow-signal` in the mockups) or a status
/// tone.
TextStyler eyebrowStyle() {
  return TextStyler()
      .fontSize(productEyebrow())
      .height(_lineHeightEyebrow)
      .fontWeight(_weightSemibold)
      .letterSpacing(_eyebrowLetterSpacing)
      .fontFamily(packageFontFamily(fontFamilyBody))
      .fontFamilyFallback(fontFamilyBodyFallback)
      .color(colorFgSubtle());
}

/// The `mono-data` role (16px/1.4, IBM Plex Mono 400): OTP code entry,
/// exported JSON block, package identifiers — spec §1.2. Never body prose,
/// never eyebrow labels.
TextStyler monoDataStyle() {
  return TextStyler()
      .fontSize(productMonoData())
      .height(_lineHeightMonoData)
      .fontWeight(_weightRegular)
      .fontFamily(packageFontFamily(fontFamilyMono))
      .fontFamilyFallback(fontFamilyMonoFallback)
      .color(colorInk());
}

/// The `button` role (16px/1, Host Grotesk 600): button label text — spec
/// §1.2. Deliberately does not set a color: a button's label color depends
/// on its variant (`colorOnAccent` on a filled surface, `colorFg` on an
/// outlined one), so callers chain `.color(...)` for their variant.
TextStyler buttonStyle() {
  return TextStyler()
      .fontSize(productButton())
      .height(_lineHeightButton)
      .fontWeight(_weightSemibold)
      .fontFamily(packageFontFamily(fontFamilyTitle))
      .fontFamilyFallback(fontFamilyTitleFallback);
}
