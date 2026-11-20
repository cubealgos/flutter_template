import 'dart:convert';

import 'package:tokens_builder/src/css/css_token_model.dart';
import 'package:tokens_builder/src/dtcg/alias_resolver.dart';
import 'package:tokens_builder/src/dtcg/flatten.dart';
import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/source_classification.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';
import 'package:tokens_builder/src/dtcg/unit_conversion.dart';

/// Runs the DTCG → CSS pipeline: parses [jsonByFileName] (the same
/// `tokens/*.json` source map `buildTokensFromSources` reads), classifies,
/// merges and alias-resolves every source exactly as the Dart pipeline
/// does (via the shared `source_classification.dart` helpers), then
/// converts every leaf to a literal CSS value instead of a `package:mix`
/// token declaration.
///
/// Deliberately does *not* reuse `extractCompositeTypography` — a
/// composite `typography.*` group (e.g. `font-size` + `font-weight` +
/// `letter-spacing`) has no single well-formed CSS shorthand value that
/// can be generated generically (the `font` shorthand requires a
/// specific token order CSS itself does not let a custom property
/// assemble safely), so every leaf, composite or not, becomes its own
/// independent CSS custom property instead — which is the natural CSS
/// shape anyway (a stylesheet consumes `--typography-title-font-size`
/// and `--typography-title-font-weight` as two separate declarations).
///
/// Unit conversion (dimension/duration/fontWeight parsing) and colour/
/// alias resolution reuse the exact same `dtcg/` pipeline stages
/// `buildTokensFromSources` uses — this function only differs in how a
/// resolved leaf is rendered to a value string.
CssBuildResult buildCssTokensFromSources(Map<String, String> jsonByFileName) {
  final parsed = jsonByFileName.map(
    (name, text) => MapEntry(name, jsonDecode(text) as Map<String, dynamic>),
  );
  final classified = classifySources(parsed, deepMerge: deepMergeTokenTrees);
  requireThemes(classified.themeFiles, const ['light', 'dark']);

  final baseLeaves = resolveAliases(flattenTokenTree(classified.base).leaves);
  final base = [
    for (final entry in baseLeaves.entries)
      _convertLeaf(entry.key, entry.value),
  ]..sort((a, b) => a.name.compareTo(b.name));

  final themeLeaves = resolveThemeLeaves(
    classified,
    deepMerge: deepMergeTokenTrees,
  );
  final colorsByTheme = {
    for (final themeEntry in themeLeaves.entries)
      themeEntry.key: [
        for (final leafEntry in themeEntry.value.entries)
          if (leafEntry.value.type == 'color')
            _convertColorLeaf(leafEntry.key, leafEntry.value),
      ]..sort((a, b) => a.name.compareTo(b.name)),
  };

  return CssBuildResult(base: base, colorsByTheme: colorsByTheme);
}

/// Converts a DTCG dot-joined [path] to a CSS custom-property name (without
/// the leading `--`) — paths are already kebab-case within each segment
/// (e.g. `paper-2`), so this only needs to join segments with `-` instead
/// of `.`.
String cssVariableName(String path) => path.replaceAll('.', '-');

CssTokenDecl _convertColorLeaf(String path, RawLeaf leaf) {
  // Validates the value using the exact same rules `tokens.g.dart`'s ARGB
  // conversion does — but the CSS value itself is the original DTCG string
  // (`#rrggbb` / `rgba(...)`), both valid CSS colour syntax already, so no
  // round-trip through an ARGB int is needed (or wanted: it would lose
  // nothing here, but going through 8-bit-per-channel int math for a
  // value CSS already understands natively is unnecessary risk).
  resolveColorValue(leaf.value as String, tokenPath: path);

  return CssTokenDecl(
    name: cssVariableName(path),
    value: leaf.value as String,
    doc: leaf.description,
  );
}

CssTokenDecl _convertLeaf(String path, RawLeaf leaf) {
  final value = switch (leaf.type) {
    'dimension' => _dimensionCss(path, leaf),
    'duration' => _durationCss(path, leaf),
    'fontWeight' => _fontWeightCss(path, leaf),
    'number' => _numberCss(path, leaf),
    'fontFamily' => _fontFamilyCss(leaf),
    'cubicBezier' => _cubicBezierCss(path, leaf),
    'string' => leaf.value as String,
    'color' => throw TokenBuildException(
      'Token "$path" is a color leaf outside a color theme file — colour '
      'tokens must live in color.<theme>.json/semantic.color.json.',
    ),
    _ => throw TokenBuildException(
      'Token "$path" has an unsupported \$type "${leaf.type}" for CSS '
      'emission.',
    ),
  };

  return CssTokenDecl(
    name: cssVariableName(path),
    value: value,
    doc: leaf.description,
  );
}

/// A DTCG dimension value (`<number>(px|rem|em)?`) is already valid CSS
/// syntax — unlike [resolveDimensionValue] (used by the Dart/Mix pipeline,
/// which has no native `rem`/`em` concept and must resolve everything to a
/// flat logical-pixel `double`), CSS natively understands all three units,
/// including `em` relative to *whatever element the custom property ends
/// up applied to* — exactly the DTCG composite-typography intent (e.g.
/// `typography.eyebrow.letter-spacing` is meant to scale with that same
/// element's own `font-size`). So the CSS emitter passes the raw value
/// through unchanged rather than resolving it, preserving `rem` (honouring
/// user text-scaling — see `typography.json`'s own `$description`) and
/// `em` (which [resolveDimensionValue] would otherwise reject outside a
/// composite entry — CSS has no such restriction). Still validated against
/// the same numeric-plus-optional-unit shape.
final RegExp _cssDimensionPattern = RegExp(r'^-?[0-9]*\.?[0-9]+(px|rem|em)?$');

String _dimensionCss(String path, RawLeaf leaf) {
  final raw = leaf.value as String;
  if (!_cssDimensionPattern.hasMatch(raw)) {
    throw TokenBuildException(
      'Token "$path" has an unparseable dimension value "$raw".',
    );
  }
  // A bare unitless number (rare in this token set, but DTCG-legal) means
  // pixels by convention — CSS requires an explicit unit for any non-zero
  // length.
  final hasUnit = RegExp(r'(px|rem|em)$').hasMatch(raw);

  return hasUnit ? raw : '${raw}px';
}

/// A DTCG `number` (a unitless line height, a scale factor) is a bare CSS
/// number: `1.5`, never `1.5px`, so it works in `line-height`, `scale()` and
/// `calc()`. The value is a JSON number; a string (even `"1.5"`) is not one.
String _numberCss(String path, RawLeaf leaf) =>
    resolveNumberValue(leaf.value, tokenPath: path).toString();

String _durationCss(String path, RawLeaf leaf) {
  final ms = resolveDurationMilliseconds(leaf.value as String, tokenPath: path);

  return '${ms}ms';
}

String _fontWeightCss(String path, RawLeaf leaf) {
  // Validates the same 100-900-step-100 rule tokens.g.dart enforces; CSS
  // `font-weight` accepts the bare number directly, no named constant
  // needed the way Flutter's `FontWeight.w600` requires.
  resolveFontWeightConstantName(leaf.value as num, tokenPath: path);

  return (leaf.value as num).toInt().toString();
}

String _fontFamilyCss(RawLeaf leaf) {
  final families = (leaf.value as List).cast<String>();

  return families.map(_quoteFontFamilyIfNeeded).join(', ');
}

final RegExp _bareFontFamily = RegExp(r'^[A-Za-z-]+$');

/// Quotes a font-family name for CSS unless it is a single bare CSS-wide
/// keyword/generic family (`serif`, `sans-serif`, `monospace`, ...) or
/// otherwise contains no whitespace/special characters — matching how a
/// hand-written CSS font stack is conventionally written (generic families
/// unquoted, named families quoted).
String _quoteFontFamilyIfNeeded(String family) {
  if (_bareFontFamily.hasMatch(family) && family == family.toLowerCase()) {
    return family;
  }

  return '"$family"';
}

String _cubicBezierCss(String path, RawLeaf leaf) {
  final points = (leaf.value as List)
      .map((n) => (n as num).toDouble())
      .toList();
  const cubicBezierPointCount = 4;
  if (points.length != cubicBezierPointCount) {
    throw TokenBuildException(
      'Token "$path" has a cubicBezier value with ${points.length} numbers, '
      'expected $cubicBezierPointCount.',
    );
  }

  return 'cubic-bezier(${points.join(', ')})';
}
