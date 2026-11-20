import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/map_generator.dart';

import 'support/fixture_workspace.dart';

/// Returns `generated.files[path]`, or throws a [StateError] if [path] is
/// missing. A missing file is a real test failure (map_generator didn't
/// generate what the test expects it to), not a "might be null at runtime"
/// case the bang operator would paper over.
String _expectFile(GeneratedMap generated, String path) =>
    generated.files[path] ??
    (throw StateError(
      '$path missing from generated output: ${generated.files.keys}',
    ));

void main() {
  // `dart test` runs with the package root as the working directory, so the
  // fixture is found relative to that rather than `Platform.script` (which
  // under the test runner points at a compiled bundle, not this file).
  final fixtureSource = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'sample_workspace'),
  );

  // Assigned in setUp/read throughout the tests/cleaned in tearDown — the
  // standard package:test fixture-per-test pattern; there's no meaningful
  // non-null default to construct it with instead.
  // ignore: solid_lints/avoid_late_keyword
  late Directory tempRoot;
  // Same fixture pattern as tempRoot above.
  // ignore: solid_lints/avoid_late_keyword
  late Directory workspaceDir;

  setUp(() {
    (:tempRoot, :workspaceDir) = copyFixtureIntoTempWorkspace(
      fixtureSource,
      'tooling_map_test_',
    );
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test(
    'findRepoRoot finds the nearest ancestor pubspec with a workspace key',
    () {
      final found = findRepoRoot(workspaceDir);
      expect(found?.path, workspaceDir.path);
    },
  );

  test('findRepoRoot returns null with no workspace pubspec above', () {
    final outside = Directory.systemTemp.createTempSync(
      'tooling_map_no_workspace_',
    );
    addTearDown(() => outside.deleteSync(recursive: true));
    expect(findRepoRoot(outside), isNull);
  });

  group('MapGenerator.generate', () {
    // Assigned in setUp/read in each test — same fixture pattern as above.
    // ignore: solid_lints/avoid_late_keyword
    late GeneratedMap generated;

    setUp(() {
      generated = MapGenerator(repoRoot: workspaceDir).generate();
    });

    test('emits docs/map.md and docs/map/pkg_a.md', () {
      expect(
        generated.files.keys,
        unorderedEquals(<String>['docs/map.md', 'docs/map/pkg_a.md']),
      );
    });

    test('index lists the member name, description and path', () {
      final index = _expectFile(generated, 'docs/map.md');
      expect(index, contains('pkg_a'));
      expect(
        index,
        contains('A sample fixture package used by map_generator_test.'),
      );
      expect(index, contains('pkg_a'));
    });

    test('member page lists public declarations of every kind', () {
      final page = _expectFile(generated, 'docs/map/pkg_a.md');
      expect(page, contains('class Greeter'));
      expect(page, contains('enum Color { red, green, blue }'));
      expect(page, contains('mixin Loud'));
      expect(page, contains('extension StringShout on String'));
      expect(page, contains('String greet(String name)'));
    });

    test('member page skips private declarations', () {
      final page = _expectFile(generated, 'docs/map/pkg_a.md');
      expect(page, isNot(contains('_PrivateHelper')));
    });

    test('member page skips generated files entirely', () {
      final page = _expectFile(generated, 'docs/map/pkg_a.md');
      expect(page, isNot(contains('pkg_a.g.dart')));
      expect(page, isNot(contains('ShouldNotAppearInMap')));
    });

    test('generation is deterministic across repeated runs', () {
      final again = MapGenerator(repoRoot: workspaceDir).generate();
      expect(again.files, generated.files);
    });
  });

  // Split into two groups (rather than one "checkAgainstDisk / writeToDisk"
  // group) so each anonymous group() closure stays under
  // function_lines_of_code's threshold — that rule has no exclude hook for
  // anonymous closures the way it does for named functions/methods.
  group('MapGenerator.checkAgainstDisk', () {
    test('reports missing files before anything is written', () {
      final generator = MapGenerator(repoRoot: workspaceDir);
      final generated = generator.generate();
      final drift = generator.checkAgainstDisk(generated);
      expect(drift, isNotEmpty);
      expect(drift.any((d) => d.startsWith('missing: docs/map.md')), isTrue);
    });

    test('is clean immediately after writeToDisk', () {
      final generator = MapGenerator(repoRoot: workspaceDir);
      final generated = generator.generate();
      generator.writeToDisk(generated);
      expect(generator.checkAgainstDisk(generated), isEmpty);
    });

    test('detects stale content edited after writeToDisk', () {
      final generator = MapGenerator(repoRoot: workspaceDir);
      final generated = generator.generate();
      generator.writeToDisk(generated);

      final memberDoc = File(
        p.join(workspaceDir.path, 'docs', 'map', 'pkg_a.md'),
      )..writeAsStringSync('hand-edited\n', mode: FileMode.append);

      final drift = generator.checkAgainstDisk(generated);
      expect(drift, contains('stale: docs/map/pkg_a.md'));
      // Sanity: the append above is what made it stale, not a fluke.
      expect(memberDoc.readAsStringSync(), endsWith('hand-edited\n'));
    });

    test('detects an extra file under docs/map', () {
      final generator = MapGenerator(repoRoot: workspaceDir);
      final generated = generator.generate();
      generator.writeToDisk(generated);

      File(p.join(workspaceDir.path, 'docs', 'map', 'stray.md'))
          .writeAsStringSync('# stray\n');

      final drift = generator.checkAgainstDisk(generated);
      expect(drift, contains('extra: docs/map/stray.md'));
    });
  });

  group('MapGenerator.writeToDisk', () {
    test('removes stray docs/map files that are no longer expected', () {
      final generator = MapGenerator(repoRoot: workspaceDir);
      final generated = generator.generate();
      generator.writeToDisk(generated);

      final strayFile = File(
        p.join(workspaceDir.path, 'docs', 'map', 'stray.md'),
      )..writeAsStringSync('# stray\n');

      generator.writeToDisk(generated);
      expect(strayFile.existsSync(), isFalse);
    });
  });
}
