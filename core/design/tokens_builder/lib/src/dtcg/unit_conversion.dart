import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

final RegExp _dimensionPattern = RegExp(r'^(-?[0-9]*\.?[0-9]+)(px|rem|em)?$');
final RegExp _rgbaPattern = RegExp(
  r'^rgba\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*\)$',
);
final RegExp _hexPattern = RegExp(r'^#([0-9a-fA-F]{6})$');

/// A DTCG `rem` dimension is multiplied by this many logical pixels per
/// root em — Flutter's (and the browser's) default root font size.
const double _pxPerRem = 16;

/// Rounding precision for [_roundToMicroPixel]: the millionth place.
const double _microPixelPrecision = 1000000;

/// `#rrggbb` and `rgba()` are read as 8-bit-per-channel color values.
const int _hexRadix = 16;

/// The maximum value of a color channel (red, green, blue or alpha),
/// 8 bits.
const int _channelMax = 255;

/// Every 32-bit ARGB color has its alpha channel fully opaque set here,
/// before a parsed alpha value (if any) overrides it.
const int _opaqueAlphaMask = 0xFF000000;

/// Bit position of the alpha, red and green channels within a 32-bit ARGB
/// integer (blue sits at bit 0, so it needs no shift).
const int _alphaShift = 24;
const int _redShift = 16;
const int _greenShift = 8;

/// A DTCG `fontWeight` value must be a multiple of 100 in this range.
const int _minFontWeight = 100;
const int _maxFontWeight = 900;
const int _fontWeightStep = 100;

/// `_dimensionPattern`'s 2nd capture group is the unit suffix.
const int _unitGroup = 2;

/// `_rgbaPattern`'s capture groups, in order.
const int _redGroup = 1;
const int _greenGroup = 2;
const int _blueGroup = 3;
const int _alphaGroup = 4;

/// Returns capture group [index] of [match]. Every call site here matches a
/// pattern whose group [index] is mandatory whenever the pattern matches at
/// all, so a `null` group can only mean the regex itself is wrong — a
/// programming error, not a normal runtime condition — hence [StateError]
/// rather than threading the nullability through every caller. Centralizes
/// what used to be a `// ignore: solid_lints/avoid_non_null_assertion` at
/// every `match.group(n)!` call site.
String _group(RegExpMatch match, int index) =>
    match.group(index) ??
    (throw StateError('Regex group $index unexpectedly unmatched.'));

/// Resolves a DTCG `dimension` `$value` to a logical-pixel [double].
///
/// Units are read explicitly, never assumed (Style Dictionary's flutter
/// transform group assumes `rem`, which silently mis-sizes tokens): `px` and a
/// bare unitless number pass through unchanged, `rem` is multiplied by 16.
/// `em` is resolved only when [emBasisPx] is supplied — the caller's own
/// `font-size`, inside a composite `typography.*` entry, which is the one
/// place `em` has a well-defined base in this token set. Any other unit, or
/// `em` with no [emBasisPx], is a [TokenBuildException] naming [tokenPath].
double resolveDimensionValue(
  String raw, {
  required String tokenPath,
  double? emBasisPx,
}) {
  final match = _dimensionPattern.firstMatch(raw);
  if (match == null) {
    throw TokenBuildException(
      'Token "$tokenPath" has an unparseable dimension value "$raw".',
    );
  }
  final number = double.parse(_group(match, 1));
  final unit = match.group(_unitGroup);

  return switch (unit) {
    null => number,
    'px' => number,
    'rem' => _roundToMicroPixel(number * _pxPerRem),
    'em' when emBasisPx != null => _roundToMicroPixel(number * emBasisPx),
    'em' => throw TokenBuildException(
      'Token "$tokenPath" uses "em" outside a composite typography entry '
      '— em has no well-defined base there.',
    ),
    _ => throw TokenBuildException(
      'Token "$tokenPath" has an unsupported dimension unit "$unit".',
    ),
  };
}

/// Rounds to the nearest millionth of a logical pixel, so a `rem`/`em`
/// multiplication (e.g. `0.18em * 7.5px`) prints as `1.35` rather than a
/// binary-float artifact like `1.3499999999999999`.
double _roundToMicroPixel(double value) =>
    (value * _microPixelPrecision).round() / _microPixelPrecision;

/// Resolves a DTCG `color` `$value` (`#rrggbb` or `rgba(r, g, b, a)`) to an
/// ARGB `Color(0x...)` integer literal, ready to interpolate into generated
/// Dart source as `Color(0x$hex)`.
int resolveColorValue(String raw, {required String tokenPath}) {
  final hex = _hexPattern.firstMatch(raw);
  if (hex != null) {
    return _opaqueAlphaMask | int.parse(_group(hex, 1), radix: _hexRadix);
  }
  final rgba = _rgbaPattern.firstMatch(raw);
  if (rgba != null) {
    return _rgbaToArgb(rgba);
  }
  throw TokenBuildException(
    'Token "$tokenPath" has an unrecognized color value "$raw" '
    '(expected #rrggbb or rgba(r, g, b, a)).',
  );
}

int _rgbaToArgb(RegExpMatch rgba) {
  final r = int.parse(_group(rgba, _redGroup));
  final g = int.parse(_group(rgba, _greenGroup));
  final b = int.parse(_group(rgba, _blueGroup));
  final a = (double.parse(_group(rgba, _alphaGroup)) * _channelMax).round();

  return (a << _alphaShift) | (r << _redShift) | (g << _greenShift) | b;
}

/// Resolves a DTCG `number` `$value` (a unitless line height, a scale
/// factor) to the JSON number it is. Anything else, a numeric string such as
/// `"1.5"` included, is a [TokenBuildException] naming [tokenPath]: DTCG
/// writes a dimension as a string with a unit and a number as a bare number,
/// and accepting both would hide a token with the wrong `$type`.
num resolveNumberValue(Object raw, {required String tokenPath}) {
  if (raw is num && raw.isFinite) return raw;
  throw TokenBuildException(
    'Token "$tokenPath" has an unparseable number value "$raw" '
    '(expected a JSON number such as 1.5).',
  );
}

/// Resolves a DTCG `duration` `$value` (e.g. `"160ms"`) to whole
/// milliseconds.
int resolveDurationMilliseconds(String raw, {required String tokenPath}) {
  final match = RegExp(r'^([0-9]+)ms$').firstMatch(raw);
  if (match == null) {
    throw TokenBuildException(
      'Token "$tokenPath" has an unparseable duration value "$raw" '
      '(expected e.g. "160ms").',
    );
  }

  return int.parse(_group(match, 1));
}

/// Resolves a DTCG `fontWeight` `$value` (100-900, a multiple of 100) to a
/// `FontWeight.w<n>` constant name, e.g. `"w600"`.
String resolveFontWeightConstantName(num raw, {required String tokenPath}) {
  final value = raw.toInt();
  final isSupported =
      value >= _minFontWeight &&
      value <= _maxFontWeight &&
      value % _fontWeightStep == 0;
  if (!isSupported) {
    throw TokenBuildException(
      'Token "$tokenPath" has an unsupported font-weight value "$raw" '
      '(expected a multiple of 100 between 100 and 900).',
    );
  }

  return 'w$value';
}
