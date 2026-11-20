import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/map_generator.dart';

/// Package directories, relative to [ChangelogCheckCommand.repoRoot], that
/// are checked for a `CHANGELOG.md` alongside every workspace member even
/// though they are not themselves a workspace member. Currently just
/// `core/architecture/mvc_lints` — deliberately unlisted in the root
/// `workspace:` key (see that package's own `pubspec.yaml` for why), but
/// still a real, independently-tagged package the same per-package
/// Keep-a-Changelog discipline applies to (see `docs/releasing.md`).
const List<String> defaultExtraPackagePaths = <String>[
  'core/architecture/mvc_lints',
];

/// Fails (non-zero exit) if any workspace member, or one of
/// [extraPackagePaths], has no `CHANGELOG.md` — the per-package
/// Keep-a-Changelog discipline `docs/releasing.md` requires "from day
/// one", not deferred to a package's first
/// real release.
class ChangelogCheckCommand {
  /// Creates a command rooted at [repoRoot], additionally checking
  /// [extraPackagePaths] (default: [defaultExtraPackagePaths]).
  ChangelogCheckCommand({
    required this.repoRoot,
    this.extraPackagePaths = defaultExtraPackagePaths,
  });

  /// The workspace root — where the root `pubspec.yaml` (with the
  /// `workspace:` key) lives.
  final String repoRoot;

  /// Package directories, relative to [repoRoot], checked in addition to
  /// the workspace members loaded from the root pubspec's `workspace:`
  /// list.
  final List<String> extraPackagePaths;

  /// Runs the check, printing a report via [out]/[err], and returns the
  /// process exit code (`0` if every checked package has a `CHANGELOG.md`,
  /// `1` otherwise).
  int run({
    void Function(String) out = _defaultOut,
    void Function(String) err = _defaultErr,
  }) {
    final packages = _checkedPackagePaths();
    final missing = <String>[
      for (final relativePath in packages)
        if (!File(p.join(repoRoot, relativePath, 'CHANGELOG.md')).existsSync())
          relativePath,
    ];

    out(
      'changelog_check: ${packages.length} package(s) checked — '
      '${packages.length - missing.length} have a CHANGELOG.md, '
      '${missing.length} missing.',
    );

    if (missing.isEmpty) return 0;

    err('changelog_check: missing CHANGELOG.md in:');
    for (final relativePath in missing) {
      err('  - $relativePath');
    }

    return 1;
  }

  /// Every workspace member's [WorkspaceMember.relativePath] plus
  /// [extraPackagePaths], sorted for deterministic output.
  List<String> _checkedPackagePaths() {
    final memberPaths = MapGenerator(repoRoot: Directory(repoRoot))
        .loadMembers()
        .map((member) => member.relativePath);

    return [...memberPaths, ...extraPackagePaths]..sort();
  }

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);
}
