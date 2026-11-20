import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/duplicate_index_cleanup.dart';

import 'support/fixture_workspace.dart';

/// Writes [contents] to `<root>/<relativePath>`, creating parent
/// directories as needed.
void _write(Directory root, String relativePath, String contents) {
  File(p.join(root.path, relativePath))
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  // Same fixture the `map` command's own tests use (test/fixtures/
  // sample_workspace: a root pubspec.yaml with `workspace: [pkg_a]`, and
  // pkg_a's own pubspec.yaml) — this command discovers workspace members
  // the identical way `MapGenerator.loadMembers` does, so reusing the
  // fixture keeps that coupling honest.
  final fixtureSource = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'sample_workspace'),
  );

  // Assigned in setUp/read throughout the tests/cleaned in tearDown — the
  // standard package:test fixture-per-test pattern; there's no meaningful
  // non-null default to construct it with instead (same pattern as
  // map_generator_test.dart, which this fixture is shared with).
  // ignore: solid_lints/avoid_late_keyword
  late Directory tempRoot;
  // Same fixture pattern as tempRoot above.
  // ignore: solid_lints/avoid_late_keyword
  late Directory workspaceDir;

  setUp(() {
    (:tempRoot, :workspaceDir) = copyFixtureIntoTempWorkspace(
      fixtureSource,
      'tooling_duplicate_index_cleanup_test_',
    );
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test('deletes the root duplicate index when present', () {
    _write(
      workspaceDir,
      '.dart_tool/solid_lints/duplicate_index.json',
      '{"files": {}}',
    );

    final deleted = deleteStaleDuplicateIndexes(repoRoot: workspaceDir);

    expect(deleted, ['.dart_tool/solid_lints/duplicate_index.json']);
    expect(
      File(
        p.join(
          workspaceDir.path,
          '.dart_tool',
          'solid_lints',
          'duplicate_index.json',
        ),
      ).existsSync(),
      isFalse,
    );
  });

  test("deletes a workspace member's own duplicate index when present", () {
    _write(
      workspaceDir,
      'pkg_a/.dart_tool/solid_lints/duplicate_index.json',
      '{"files": {}}',
    );

    final deleted = deleteStaleDuplicateIndexes(repoRoot: workspaceDir);

    expect(deleted, ['pkg_a/.dart_tool/solid_lints/duplicate_index.json']);
  });

  test('deletes both the root and every member index in one call', () {
    _write(
      workspaceDir,
      '.dart_tool/solid_lints/duplicate_index.json',
      '{"files": {}}',
    );
    _write(
      workspaceDir,
      'pkg_a/.dart_tool/solid_lints/duplicate_index.json',
      '{"files": {}}',
    );

    final deleted = deleteStaleDuplicateIndexes(repoRoot: workspaceDir);

    expect(
      deleted,
      unorderedEquals(<String>[
        '.dart_tool/solid_lints/duplicate_index.json',
        'pkg_a/.dart_tool/solid_lints/duplicate_index.json',
      ]),
    );
  });

  test('is a no-op (no error, empty result) when no index exists', () {
    final deleted = deleteStaleDuplicateIndexes(repoRoot: workspaceDir);

    expect(deleted, isEmpty);
  });

  test('never deletes a file with a different name under solid_lints/', () {
    _write(
      workspaceDir,
      '.dart_tool/solid_lints/other_cache.json',
      '{"kept": true}',
    );

    final deleted = deleteStaleDuplicateIndexes(repoRoot: workspaceDir);

    expect(deleted, isEmpty);
    expect(
      File(
        p.join(
          workspaceDir.path,
          '.dart_tool',
          'solid_lints',
          'other_cache.json',
        ),
      ).existsSync(),
      isTrue,
    );
  });

  test('never deletes an unrelated file elsewhere under .dart_tool/', () {
    _write(
      workspaceDir,
      '.dart_tool/package_config.json',
      '{"configVersion": 2}',
    );
    _write(
      workspaceDir,
      '.dart_tool/build/duplicate_index.json',
      '{"unrelated": true}',
    );

    final deleted = deleteStaleDuplicateIndexes(repoRoot: workspaceDir);

    expect(deleted, isEmpty);
    expect(
      File(p.join(workspaceDir.path, '.dart_tool', 'package_config.json'))
          .existsSync(),
      isTrue,
    );
    expect(
      File(
        p.join(
          workspaceDir.path,
          '.dart_tool',
          'build',
          'duplicate_index.json',
        ),
      ).existsSync(),
      isTrue,
    );
  });
}
