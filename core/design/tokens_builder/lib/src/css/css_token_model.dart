/// One resolved CSS custom property: its variable name (without the leading
/// `--`) and its literal CSS value, ready to interpolate as
/// `--<name>: <value>;`.
///
// This file groups both CSS-emission result types together, so its name
// doesn't match this first declaration — same convention as
// core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class CssTokenDecl {
  /// Creates a resolved CSS custom-property declaration.
  const CssTokenDecl({required this.name, required this.value, this.doc});

  /// The custom-property name, e.g. `space-4` (rendered as `--space-4`).
  final String name;

  /// The literal CSS value, e.g. `16px`, `#f5f5f5`, `cubic-bezier(...)`.
  final String value;

  /// A `$description`, if the source token declared one — rendered as a
  /// `/* ... */` comment above the declaration.
  final String? doc;
}

/// Every resolved CSS custom property the emitter needs: theme-independent
/// declarations once, plus one set of colour declarations per discovered
/// theme (keyed the same way `BuildTokensResult.themes` is).
class CssBuildResult {
  /// Creates a CSS build result.
  const CssBuildResult({required this.base, required this.colorsByTheme});

  /// Every non-colour custom property — dimensions, typography, motion,
  /// font families and any other scalar/plain token. Identical in every
  /// theme, so declared once under `:root`.
  final List<CssTokenDecl> base;

  /// Every colour custom property, by theme name (`light`, `dark`, ...) —
  /// the same theme names `BuildTokensResult.themes` discovers. `light` is
  /// emitted under the unconditional `:root` block; every other theme is
  /// emitted inside its own `@media (prefers-color-scheme: ...)` override.
  final Map<String, List<CssTokenDecl>> colorsByTheme;
}
