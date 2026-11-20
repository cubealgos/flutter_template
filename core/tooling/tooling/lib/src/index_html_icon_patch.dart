/// The canonical `apple-touch-icon` link tag this file's patch installs —
/// see `icon_image_generation.dart`'s `appleTouchIconSize` for why 180.
const String appleTouchIconLinkTag =
    '<link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">';

/// The canonical legacy-favicon link tag this file's patch installs,
/// alongside the PNG favicon link the Flutter web template already ships
/// (`<link rel="icon" type="image/png" ...>`, left untouched — see
/// [_pngFaviconAnchor]).
const String faviconIcoLinkTag =
    '<link rel="icon" type="image/x-icon" href="favicon.ico">';

/// Matches a previously patched `apple-touch-icon` link line (any `href`/
/// `sizes`, so a stale value from an older run is replaced, not
/// duplicated), including its leading indentation and trailing newline.
final RegExp _appleTouchIconLine = RegExp(
  r'^[ \t]*<link rel="apple-touch-icon"[^>]*>[ \t]*\n?',
  multiLine: true,
);

/// Matches a previously patched `favicon.ico` link line, same shape as
/// [_appleTouchIconLine].
final RegExp _faviconIcoLine = RegExp(
  r'^[ \t]*<link rel="icon" type="image/x-icon"[^>]*>[ \t]*\n?',
  multiLine: true,
);

/// The Flutter web template's own PNG favicon link — present in every
/// `web/index.html` this template generates (confirmed against
/// flutter_launcher_icons' `lib/web/web_icon_generator.dart` source: it
/// writes `web/favicon.png` but never touches `index.html`, so this line
/// is never removed or moved by that tool). Used as a stable insertion
/// anchor so patching is idempotent — see [patchIndexHtmlIconTags].
final RegExp _pngFaviconAnchor = RegExp(
  r'([ \t]*)<link rel="icon" type="image/png"[^>]*>',
);

/// Matches three or more consecutive newlines — i.e. two or more fully
/// blank lines in a row (a line containing only whitespace still counts as
/// blank here since [normalizeIndexHtmlBlankLines] strips trailing
/// whitespace from every line first).
final RegExp _repeatedBlankLines = RegExp(r'\n{3,}');

/// Trims trailing whitespace from every line of [original] and collapses
/// any run of blank lines down to exactly one.
///
/// Exists because flutter_native_splash's own `web/index.html` patcher
/// (`dart run flutter_native_splash:create`, run by `icons_command.dart`
/// before this file's functions ever see the content) is not itself
/// idempotent: verified empirically (running it repeatedly against the
/// same file) that each run leaves a handful of new whitespace-only
/// blank lines behind at the spots where it inserts and removes its own
/// markers, and those blank lines accumulate without bound across
/// repeated runs. The accumulation is purely cosmetic (no tag or content
/// changes), but it does mean a second `dart run melos run icons` would
/// otherwise leave `web/index.html` dirty. Normalizing here — after the
/// external generator runs, as part of this template's own gap-fill step
/// — absorbs that upstream non-idempotency so the whole `icons` command is
/// idempotent even though flutter_native_splash's own patch in isolation
/// is not.
String normalizeIndexHtmlBlankLines(String original) {
  final trimmedLines = original
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n');

  return trimmedLines.replaceAll(_repeatedBlankLines, '\n\n');
}

/// Rewrites [original] (a `web/index.html`'s contents) so it links
/// [appleTouchIconLinkTag] and [faviconIcoLinkTag] — the two `<head>` tags
/// neither flutter_launcher_icons nor flutter_native_splash writes for web
/// (flutter_launcher_icons only ever writes `web/favicon.png` and the
/// existing `Icon-*.png`s; see `icons_command.dart`).
///
/// Idempotent: strips any previously patched copy of either tag first,
/// then reinserts both right before the template's own PNG favicon link —
/// so `patchIndexHtmlIconTags(patchIndexHtmlIconTags(x)) ==
/// patchIndexHtmlIconTags(x)`, verified by
/// `index_html_icon_patch_test.dart`. Throws [FormatException] if
/// [_pngFaviconAnchor] isn't found — this template's `web/index.html`
/// always has it, so its absence means the file was hand-edited into an
/// unexpected shape this patch can't anchor against.
String patchIndexHtmlIconTags(String original) {
  final stripped = original
      .replaceAll(_appleTouchIconLine, '')
      .replaceAll(_faviconIcoLine, '');

  final anchor = _pngFaviconAnchor.firstMatch(stripped);
  if (anchor == null) {
    throw const FormatException(
      'web/index.html: expected a '
      '`<link rel="icon" type="image/png" ...>` tag (the Flutter web '
      "template's own favicon.png link) to anchor the patch against — not "
      'found.',
    );
  }
  final indent = anchor.group(1) ?? '';

  return stripped.replaceRange(
    anchor.start,
    anchor.start,
    '$indent$appleTouchIconLinkTag\n$indent$faviconIcoLinkTag\n',
  );
}
