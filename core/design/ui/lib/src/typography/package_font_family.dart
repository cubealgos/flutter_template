/// Qualifies a font family bundled by this package's own `pubspec.yaml`
/// `fonts:` declaration (`fontFamilyTitle`/`fontFamilyBody`/`fontFamilyMono`
/// in `tokens.g.dart`) so Flutter can actually find it at render time.
///
/// A font a package declares is only reachable, package-external, as
/// `packages/<package>/<family>` — Flutter's asset-resolution convention for
/// package-bundled fonts (see the Flutter docs on
/// [package fonts](https://docs.flutter.dev/cookbook/design/fonts#from-a-package)).
/// Passing the bare family name (what `tokens.g.dart` emits, and what
/// `tokens/*.json`/the website's generated `tokens.g.css` must keep, since
/// neither goes through Flutter's package-font resolution) silently falls
/// back to the platform default (Roboto) instead of throwing.
///
/// Never applied to [family]'s own fallback list (`fontFamilyTitleFallback`
/// etc.): those name platform-system fonts (`system-ui`, `monospace`, …),
/// not assets this package bundles, so they must stay unprefixed.
String packageFontFamily(String family) => 'packages/ui/$family';
