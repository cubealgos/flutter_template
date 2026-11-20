/// The `package:mix` token class (and `MixScope` value-map bucket) a
/// resolved, non-color scalar token maps to.
///
// This file groups every resolved-token model type together, so its name
// doesn't match this first declaration — same convention as
// core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
enum ScalarTokenKind {
  /// `SpaceToken<double>` — `MixScope(spaces: ...)`.
  space,

  /// `RadiusToken<Radius>` — `MixScope(radii: ...)`.
  radius,

  /// `DoubleToken<double>` — `MixScope(doubles: ...)`.
  double_,

  /// `TextStyleToken<TextStyle>` — `MixScope(textStyles: ...)`.
  textStyle,

  /// `DurationToken<Duration>` — no dedicated `MixScope` parameter; carried
  /// in the generic `MixScope(tokens: ...)` map.
  duration,

  /// `FontWeightToken<FontWeight>` — `MixScope(fontWeights: ...)`.
  fontWeight,
}

/// A resolved `MixToken` declaration whose value does not vary between
/// themes (everything except color: spacing, radii, other dimensions, text
/// styles, durations, font weights).
class ResolvedScalarToken {
  /// Creates a resolved non-color token.
  const ResolvedScalarToken({
    required this.path,
    required this.identifier,
    required this.kind,
    required this.valueSource,
    this.doc,
  });

  /// The DTCG dot-joined path, e.g. `space.4`.
  final String path;

  /// The generated Dart identifier, e.g. `space4`.
  final String identifier;

  /// Which `MixToken` subclass and `MixScope` bucket this belongs to.
  final ScalarTokenKind kind;

  /// The Dart literal source for this token's value, e.g. `16.0`.
  final String valueSource;

  /// Dartdoc text for the generated declaration, if the token (or, for a
  /// composite `typography.*` entry, its group) declared a `$description`.
  final String? doc;
}

/// A resolved `ColorToken` declaration, with one ARGB value per theme.
class ResolvedColorToken {
  /// Creates a resolved color token.
  const ResolvedColorToken({
    required this.path,
    required this.identifier,
    required this.argbByTheme,
    this.doc,
  });

  /// The DTCG dot-joined path, e.g. `color.paper`.
  final String path;

  /// The generated Dart identifier, e.g. `colorPaper`.
  final String identifier;

  /// This token's resolved 32-bit ARGB value, by theme name (`light`,
  /// `dark`, ...).
  final Map<String, int> argbByTheme;

  /// Dartdoc text for the generated declaration.
  final String? doc;
}

/// A plain (non-`MixToken`) generated `const` — for DTCG value types
/// `package:mix` has no token class for: `fontFamily` (emitted as a
/// `String` plus a `List<String>` fallback) and `cubicBezier` (emitted as a
/// `Cubic`, since `MixScope` has no curve token bucket to put a token in).
class PlainConstDecl {
  /// Creates a plain generated constant.
  const PlainConstDecl({
    required this.identifier,
    required this.dartType,
    required this.valueSource,
    this.doc,
  });

  /// The generated Dart identifier.
  final String identifier;

  /// The declared Dart type, e.g. `Cubic` or `String`.
  final String dartType;

  /// The Dart literal source for this constant's value.
  final String valueSource;

  /// Dartdoc text for the generated declaration.
  final String? doc;
}

/// Every resolved declaration the emitter needs, plus the theme names to
/// generate an `AppTokenValues` collection for.
class BuildTokensResult {
  /// Creates a build result.
  const BuildTokensResult({
    required this.themes,
    required this.colors,
    required this.scalars,
    required this.plainConsts,
  });

  /// Theme names discovered from `color.<theme>.json` files, sorted with
  /// `light` and `dark` guaranteed present.
  final List<String> themes;

  /// Every resolved `ColorToken`.
  final List<ResolvedColorToken> colors;

  /// Every resolved non-color `MixToken`.
  final List<ResolvedScalarToken> scalars;

  /// Every resolved plain (non-`MixToken`) constant.
  final List<PlainConstDecl> plainConsts;
}

/// The result of pulling every composite `typography.*` entry (a group
/// whose direct children include a `font-size` token) out of a flattened,
/// alias-resolved leaf map — see `extractCompositeTypography`.
class CompositeTypographyResult {
  /// Creates a composite-typography extraction result.
  const CompositeTypographyResult({
    required this.tokens,
    required this.consumedPaths,
  });

  /// One [ResolvedScalarToken] (kind [ScalarTokenKind.textStyle]) per
  /// composite entry found.
  final List<ResolvedScalarToken> tokens;

  /// Every leaf path absorbed into a composite entry — the caller must not
  /// also emit these as standalone tokens.
  final Set<String> consumedPaths;
}
