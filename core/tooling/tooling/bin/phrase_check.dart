import 'dart:io';

import 'package:tooling/src/map_generator.dart' show findRepoRoot;
import 'package:tooling/src/phrase_check_command.dart';

/// Exit code used when no repo root can be found above the current directory.
const int _repoRootNotFoundExitCode = 2;

/// `phrase_check`: scans the app and website copy (and any `sources:` listed
/// in `tool/phrase-check.yaml`) for the forbidden phrases in that file,
/// matched case-insensitively and word-aware with German forms, and exits
/// non-zero on any occurrence no keyed exception covers.
///
/// Usage: `fvm dart run tooling:phrase_check` (repo root or a worktree).
void main(List<String> _) {
  final repoRoot = findRepoRoot(Directory.current);
  if (repoRoot == null) {
    stderr.writeln(
      'phrase_check: could not find repo root (no pubspec.yaml with a '
      '"workspace:" key found above ${Directory.current.path}).',
    );
    exit(_repoRootNotFoundExitCode);
  }

  exit(PhraseCheckCommand(repoRoot: repoRoot.path).run());
}
