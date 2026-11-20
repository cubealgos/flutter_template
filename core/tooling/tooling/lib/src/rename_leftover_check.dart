import 'dart:io';

import 'package:path/path.dart' as p;

/// Directory names never descended into while scanning for rename
/// leftovers: git's own history (the allow-listed "git history" category —
/// nothing under `.git/` is source, and rewriting a past commit is exactly
/// what this repo's `CLAUDE.md` forbids), and build/tooling caches that are
/// either gitignored and regenerated fresh (`.dart_tool`, `build`, `.fvm`,
/// `Pods`) or simply not source text.
const List<String> renameScanExcludedDirNames = <String>[
  '.git',
  '.dart_tool',
  '.fvm',
  'build',
  'Pods',
];

/// File extensions never treated as text while scanning — binary assets a
/// case-insensitive text search can't meaningfully match against, and that
/// would otherwise risk a `FormatException` decoding them as UTF-8.
const List<String> renameScanBinaryExtensions = <String>[
  '.png',
  '.ico',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.icns',
  '.ttf',
  '.otf',
  '.woff',
  '.woff2',
  '.jar',
  '.keystore',
  '.jks',
];

/// Paths (relative to the repo root, forward-slash-separated) `rename`'s
/// leftover check treats as pre-existing, deliberately-out-of-scope hits —
/// on top of the generic "CHANGELOG" category `RenameCommand` also
/// allow-lists by pattern (any file whose basename is `CHANGELOG.md`, at
/// any depth — root, `core/tooling/tooling/`, `apps/app/`, ... — since a
/// changelog is history and rewriting it would misrepresent it).
/// Every entry here is a *specific file*, never a directory prefix: everywhere the old name/org could realistically be
/// renamed (`core/architecture/mvc_lints`'
/// own plugin name, `core/tooling/tooling`'s own non-`rename_*` dartdoc
/// examples) has instead been neutralized at the source — see
/// `core/architecture/mvc_lints/lib/main.dart` (plugin
/// name `mvc_lints`, no longer template-branded) and
/// `core/tooling/tooling/lib/src/git_remote_info.dart` (a neutral `my_app`
/// example). What's left below is only what genuinely can't be neutralized
/// without losing the thing it documents: two confirmed-unrelated false
/// positives, and `rename`'s own source/tests, which necessarily keep
/// saying `flutter_template`/`com.example` forever to describe *what an
/// unrenamed clone looks like* — that's the tool's job, not this clone's
/// own leftover state. One more category: `docs/design/spec.md` and
/// `docs/design/mockups/canvas.json` are a dated, already-approved design
/// record of work done *on this template's own reference app* — the same
/// "historical, not living" reasoning as the generic `CHANGELOG.md`
/// allow-list `RenameCommand._checkNoLeftovers` applies, just not
/// expressible as that one filename pattern. Rewriting "flutter_template
/// app — UI design spec" to a clone's own name would misrepresent whose
/// design decision it records; a clone that wants its own equivalent
/// writes a new one rather than inheriting a relabelled one.
const List<String> renameLeftoverAllowList = <String>[
  // `flutter create`'s own generated comment, from the Flutter SDK's
  // project template — "the Flutter template" here means Flutter's own
  // `flutter create` scaffolding mechanism, not this repo's
  // clone-and-rename template. Confirmed unrelated to `flutter_template`
  // the workspace name by reading the file.
  'apps/app/android/gradle.properties',
  // A W3C Design Tokens `$extensions` vendor-namespace key
  // (`com.example.audience`) — reverse-domain notation reused as a private
  // JSON Schema extension key for `core/design/ui`'s own tooling, unrelated to
  // the app's bundle/org identity `rename` rewrites. Out of `rename`'s
  // scope (core/design/ui isn't a native-platform or app-identity surface);
  // renaming it would risk breaking `tokens_builder`'s own extension
  // lookups for no benefit.
  'core/design/ui/tokens/color.dark.json',
  'core/design/ui/tokens/color.light.json',
  // A dated, already-approved UI design record for this template's own
  // reference app (`docs/design/spec.md`'s own opening line: "approved
  // on 2026-09-26") — historical, like a changelog
  // entry, not living documentation a clone's own rename should relabel.
  'docs/design/spec.md',
  'docs/design/mockups/canvas.json',
  // `rename`'s own implementation: dartdoc explaining the old-identity
  // concept (`OldIdentity.templateToken`'s own `flutter_template` example,
  // this very allow-list's comments, ...) and one runtime message string
  // ("replaces the flutter_template placeholder").
  'core/tooling/tooling/lib/src/rename_identity.dart',
  'core/tooling/tooling/lib/src/rename_leftover_check.dart',
  'core/tooling/tooling/lib/src/rename_text_rewrite.dart',
  'core/tooling/tooling/lib/src/rename_command.dart',
  // `rename`'s own tests: fixtures exercising the old-identity shape on
  // purpose (a fake clone's `pubspec.yaml`/`i18n` content, the exact
  // strings the leftover check itself is unit-tested against).
  'core/tooling/tooling/test/rename_identity_test.dart',
  'core/tooling/tooling/test/rename_text_rewrite_test.dart',
  'core/tooling/tooling/test/rename_leftover_check_test.dart',
  'core/tooling/tooling/test/rename_command_test.dart',
  'core/tooling/tooling/test/package_rename_config_yaml_test.dart',
];

/// One unresolved hit: [relativePath] (forward-slash, relative to the repo
/// root) and the 1-based [line] number [excerpt] was found on.
//
// This file is named for what it does (findRenameLeftovers, below), not
// for this plain result-holder class — same convention as
// `branch_lint_result.dart`.
// ignore: solid_lints/prefer_match_file_name
class RenameLeftover {
  /// Creates a leftover hit.
  const RenameLeftover({
    required this.relativePath,
    required this.line,
    required this.excerpt,
  });

  /// The file's path, relative to the repo root, forward-slash-separated.
  final String relativePath;

  /// The 1-based line number [excerpt] was found on.
  final int line;

  /// The matching line's text, trimmed.
  final String excerpt;

  @override
  String toString() => '$relativePath:$line: $excerpt';
}

/// Case-insensitively searches every text file under [repoRoot] for any of
/// [searchTerms], skipping [renameScanExcludedDirNames] directories and
/// [renameScanBinaryExtensions] files, and returns every hit whose
/// repo-relative path isn't covered by [isAllowListed].
///
/// This is `rename`'s final safety net (see `rename_command.dart`): run
/// after package_rename and every Dart-level rewrite, it doesn't trust that
/// either one actually caught everything — package_rename logs and
/// continues past a per-platform failure rather than raising it (confirmed
/// against its own `lib/src/platforms/*.dart`: each `_set*Configurations`
/// has its own try/catch that never rethrows) — so a silently-skipped
/// platform still shows up here.
List<RenameLeftover> findRenameLeftovers({
  required String repoRoot,
  required List<String> searchTerms,
  required bool Function(String relativePath) isAllowListed,
}) {
  final lowerTerms = searchTerms
      .where((term) => term.isNotEmpty)
      .map((term) => term.toLowerCase())
      .toList();
  if (lowerTerms.isEmpty) return const <RenameLeftover>[];

  final leftovers = <RenameLeftover>[];
  final root = Directory(repoRoot);
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p
        .relative(entity.path, from: repoRoot)
        .replaceAll(Platform.pathSeparator, '/');
    if (_isExcluded(relative) || isAllowListed(relative)) continue;
    if (renameScanBinaryExtensions.contains(p.extension(relative))) continue;

    final String content;
    try {
      content = entity.readAsStringSync();
    } on FormatException {
      continue; // Not valid UTF-8 text — treat as binary, skip.
    }

    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      if (lowerTerms.any(lowerLine.contains)) {
        leftovers.add(
          RenameLeftover(
            relativePath: relative,
            line: i + 1,
            excerpt: lines[i].trim(),
          ),
        );
      }
    }
  }

  return leftovers;
}

bool _isExcluded(String relativePath) {
  final segments = p.split(relativePath);

  return segments.any(renameScanExcludedDirNames.contains);
}
