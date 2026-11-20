import 'dart:io';

import 'package:tooling/src/duplicate_index_cleanup.dart';
import 'package:tooling/src/map_generator.dart' show findRepoRoot;

/// Exit code used when no repo root (a `pubspec.yaml` with a `workspace:`
/// key) can be found above the current directory.
const int _repoRootNotFoundExitCode = 2;

/// `clean_duplicate_index`: deletes every stale
/// `.dart_tool/solid_lints/duplicate_index.json` in the workspace (root and
/// members) before `melos run analyze` runs the root `dart analyze`
/// — see [deleteStaleDuplicateIndexes]'s doc comment for why this index
/// can't be trusted across `dart analyze` runs.
///
/// Usage: `fvm dart run tooling:clean_duplicate_index` (repo root or a
/// worktree — resolves the workspace relative to [Directory.current]).
Future<void> main(List<String> _) async {
  final repoRoot = findRepoRoot(Directory.current);
  if (repoRoot == null) {
    stderr.writeln(
      'clean_duplicate_index: could not find repo root (no pubspec.yaml '
      'with a "workspace:" key found above ${Directory.current.path}).',
    );
    exit(_repoRootNotFoundExitCode);
  }

  final deleted = deleteStaleDuplicateIndexes(repoRoot: repoRoot);
  for (final path in deleted) {
    stdout.writeln('clean_duplicate_index: deleted $path');
  }
  stdout.writeln(
    'clean_duplicate_index: removed ${deleted.length} stale solid_lints '
    'duplicate index file(s).',
  );
  exit(0);
}
