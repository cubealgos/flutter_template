/// Pure text-transformation functions `rename` applies across the
/// workspace's Dart-level surface: pubspec `name:` lines, `flutter_template`
/// mentions in prose, `package:<old>/` imports/exports, and the `appTitle`
/// i18n placeholder. Kept free of `dart:io` so each is exercised directly
/// against literal strings in `rename_text_rewrite_test.dart` — the actual
/// file reads/writes happen in `rename_command.dart`.
library;

/// Matches a pubspec's top-level `name:` line — the first line starting
/// with `name:` at column 0 (a nested `name:` under `dependencies:` etc. is
/// always indented, so this never matches those).
final RegExp _pubspecNameLine = RegExp(r'^name:.*$', multiLine: true);

/// Rewrites [pubspecContent]'s top-level `name:` line to [newName],
/// preserving every other line (comments included) exactly. Throws a
/// [FormatException] if no top-level `name:` line is found — every
/// pubspec.yaml in this workspace has one, so its absence means the file
/// isn't what this function expects.
String rewritePubspecName(String pubspecContent, String newName) {
  if (!_pubspecNameLine.hasMatch(pubspecContent)) {
    throw const FormatException('pubspec.yaml has no top-level "name:" line.');
  }

  return pubspecContent.replaceFirst(_pubspecNameLine, 'name: $newName');
}

/// Replaces every occurrence of [oldToken] in [content] with [newToken] — a
/// plain, case-sensitive substring replace.
///
/// Used for `flutter_template`-shaped mentions: because the workspace root
/// pubspec's `name: flutter_template_workspace` and
/// `core/tooling/tooling/pubspec.yaml`'s `description: Repo tooling for the
/// flutter_template workspace...` both contain the token as a substring,
/// one substitution pass across a pubspec's full text correctly rewrites
/// both the `name:` line and any prose mention in the same step —
/// `rewritePubspecName` above only needs to run where the *whole* `name:`
/// value changes to something that isn't just token substitution (the
/// workspace root's own `_workspace` suffix, or `apps/app`'s `--app-package`
/// rename).
String replaceTemplateToken(
  String content, {
  required String oldToken,
  required String newToken,
}) => content.replaceAll(oldToken, newToken);

/// Rewrites every `package:<oldPackage>/` import/export prefix in
/// [dartSource] to `package:<newPackage>/`. Anchored to `/` so
/// `package:app/` never matches a longer package name that merely starts
/// with the same letters (e.g. `package:appwrite/`).
String rewritePackageImports(
  String dartSource, {
  required String oldPackage,
  required String newPackage,
}) {
  final pattern = RegExp('package:${RegExp.escape(oldPackage)}/');

  return dartSource.replaceAll(pattern, 'package:$newPackage/');
}

/// Matches an i18n source JSON's top-level `"appTitle": "..."` field.
final RegExp _appTitleField = RegExp(r'"appTitle":\s*".*?"');

/// Matches `apps/website/lib/src/site_constants.dart`'s
/// `const String productName = "...";` declaration.
final RegExp _websiteProductNameField = RegExp(
  '''const String productName = ['"].*?['"];''',
);

/// Rewrites [dartSource] (`apps/website/lib/src/site_constants.dart`'s
/// content) so its `productName` constant reads [newDisplay] instead —
/// the website's single source for its brand name in the nav, footer,
/// `<title>`s and Open Graph tags (every one of those interpolates
/// `productName` rather than repeating the literal string, so rewriting
/// this one declaration is enough — see that file's own dartdoc).
///
/// Throws a [FormatException] if no `productName` declaration is found.
String rewriteWebsiteProductName(String dartSource, String newDisplay) {
  if (!_websiteProductNameField.hasMatch(dartSource)) {
    throw const FormatException(
      'site_constants.dart has no "const String productName = ...;" '
      'declaration.',
    );
  }
  final escaped = newDisplay.replaceAll("'", r"\'");

  return dartSource.replaceFirst(
    _websiteProductNameField,
    "const String productName = '$escaped';",
  );
}

/// Rewrites [i18nJson]'s `appTitle` field to [newDisplay] (JSON-escaped).
/// Regex-based rather than a full parse/re-serialize so every other key's
/// order and formatting survives untouched — `en.i18n.json`/`de.i18n.json`
/// are slang source files, hand-edited elsewhere in the app.
///
/// Throws a [FormatException] if no `appTitle` field is found.
String rewriteI18nAppTitle(String i18nJson, String newDisplay) {
  if (!_appTitleField.hasMatch(i18nJson)) {
    throw const FormatException('i18n source has no "appTitle" field.');
  }
  final escaped = newDisplay.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  return i18nJson.replaceFirst(_appTitleField, '"appTitle": "$escaped"');
}
