import 'dart:io';

import 'package:path/path.dart' as p;

import 'copy_dir.dart';

/// Creates a fresh temp directory (named with [tempPrefix]) and copies
/// [fixtureSource] into a `sample_workspace` subdirectory of it, returning
/// both so the caller's own `setUp` can assign its `late` fixture
/// variables directly and its `tearDown` can delete `tempRoot`
/// (recursively) afterward.
///
/// Shared by every test that mutates its own disposable copy of
/// `test/fixtures/sample_workspace` (`map_generator_test.dart`,
/// `duplicate_index_cleanup_test.dart`) — the two calls were flagged as a
/// structural duplicate (differing only in [tempPrefix]) once both existed.
({Directory tempRoot, Directory workspaceDir}) copyFixtureIntoTempWorkspace(
  Directory fixtureSource,
  String tempPrefix,
) {
  final tempRoot = Directory.systemTemp.createTempSync(tempPrefix);
  final workspaceDir = Directory(p.join(tempRoot.path, 'sample_workspace'));
  copyDirRecursively(fixtureSource, workspaceDir);

  return (tempRoot: tempRoot, workspaceDir: workspaceDir);
}
