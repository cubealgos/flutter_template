import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/changelog_check_command.dart';

import 'support/fixture_workspace.dart';

void main() {
  // `dart test` runs with the package root as the working directory, so the
  // fixture is found relative to that rather than `Platform.script` — same
  // reasoning as `map_generator_test.dart`, which this fixture is shared
  // with.
  final fixtureSource = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'sample_workspace'),
  );

  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late Directory tempRoot;
  // Same fixture pattern as tempRoot above.
  // ignore: solid_lints/avoid_late_keyword
  late Directory workspaceDir;
  // Same fixture pattern as tempRoot above.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> out;
  // Same fixture pattern as tempRoot above.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> err;

  setUp(() {
    (:tempRoot, :workspaceDir) = copyFixtureIntoTempWorkspace(
      fixtureSource,
      'tooling_changelog_check_test_',
    );
    out = <String>[];
    err = <String>[];
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test('exits 0 when every workspace member has a CHANGELOG.md', () {
    File(p.join(workspaceDir.path, 'pkg_a', 'CHANGELOG.md'))
        .writeAsStringSync('# Changelog\n');

    final command = ChangelogCheckCommand(
      repoRoot: workspaceDir.path,
      extraPackagePaths: const [],
    );

    final exitCode = command.run(out: out.add, err: err.add);

    expect(exitCode, 0);
    expect(out.join('\n'), contains('1 package(s) checked'));
    expect(out.join('\n'), contains('1 have a CHANGELOG.md, 0 missing'));
    expect(err, isEmpty);
  });

  test('exits 1 and names the package when a workspace member has no '
      'CHANGELOG.md', () {
    final command = ChangelogCheckCommand(
      repoRoot: workspaceDir.path,
      extraPackagePaths: const [],
    );

    final exitCode = command.run(out: out.add, err: err.add);

    expect(exitCode, 1);
    expect(out.join('\n'), contains('0 have a CHANGELOG.md, 1 missing'));
    expect(err.join('\n'), contains('missing CHANGELOG.md in:'));
    expect(err.join('\n'), contains('- pkg_a'));
  });

  test('checks extraPackagePaths alongside workspace members, even though '
      "they aren't listed in the root pubspec's workspace: key", () {
    File(p.join(workspaceDir.path, 'pkg_a', 'CHANGELOG.md'))
        .writeAsStringSync('# Changelog\n');
    Directory(p.join(workspaceDir.path, 'extra_pkg'))
        .createSync(recursive: true);

    final command = ChangelogCheckCommand(
      repoRoot: workspaceDir.path,
      extraPackagePaths: const ['extra_pkg'],
    );

    final exitCode = command.run(out: out.add, err: err.add);

    expect(exitCode, 1);
    expect(out.join('\n'), contains('2 package(s) checked'));
    expect(err.join('\n'), contains('- extra_pkg'));
  });

  test('the real repo has a CHANGELOG.md for every checked package', () {
    // The one test in this file that runs against the real workspace
    // rather than the fixture — a deliberate exception to the "tests use
    // the temp fixture" pattern above, since this is the actual guard the
    // .github/workflows/changelog-check.yml CI job relies on, and a fixture can never
    // catch a real package that is missing one.
    final realRepoRoot = p.normalize(
      p.join(Directory.current.path, '..', '..', '..'),
    );
    final command = ChangelogCheckCommand(repoRoot: realRepoRoot);

    final exitCode = command.run(out: out.add, err: err.add);

    expect(exitCode, 0, reason: err.join('\n'));
  });
}
