import 'dart:io';

import 'package:tooling/src/changelog_check_command.dart';
import 'package:tooling/src/map_generator.dart' show findRepoRoot;

/// Exit code used when no repo root (a `pubspec.yaml` with a `workspace:`
/// key) can be found above the current directory.
const int _repoRootNotFoundExitCode = 2;

/// `changelog_check`: fails if any workspace member, or
/// `core/architecture/mvc_lints`, has no `CHANGELOG.md` — the per-package
/// Keep-a-Changelog discipline `docs/releasing.md` requires from day one.
///
/// Usage: `fvm dart run tooling:changelog_check` (repo root or a worktree
/// — resolves the workspace relative to [Directory.current]).
void main(List<String> _) {
  final repoRoot = findRepoRoot(Directory.current);
  if (repoRoot == null) {
    stderr.writeln(
      'changelog_check: could not find repo root (no pubspec.yaml with a '
      '"workspace:" key found above ${Directory.current.path}).',
    );
    exit(_repoRootNotFoundExitCode);
  }

  final command = ChangelogCheckCommand(repoRoot: repoRoot.path);
  exit(command.run());
}
