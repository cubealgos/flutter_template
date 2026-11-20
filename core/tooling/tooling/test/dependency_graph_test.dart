import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/dependency_graph.dart';
import 'package:tooling/src/graph_package.dart';
import 'package:tooling/src/process_runner.dart';

import 'support/fake_dart_process_runner.dart';
import 'support/fake_dependency_graph.dart';

/// [graph]'s entry for [name] — fails the test loudly (via `expect`,
/// before the one unavoidable `!`) rather than a raw `TypeError` if a
/// fixture ever drifts and a name this test expects goes missing.
GraphPackage packageNamed(Map<String, GraphPackage> graph, String name) {
  final pkg = graph[name];
  expect(pkg, isNotNull, reason: "'$name' missing from the fake graph.");

  // The expect() above already fails the test if pkg is null.
  // ignore: solid_lints/avoid_non_null_assertion
  return pkg!;
}

void main() {
  group('resolveDependencyGraph: parsing', () {
    test('parses every package, keyed by name', () async {
      final runner = FakeDartProcessRunner('fake_dart', fakePubDepsJson);
      final graph = await _loadFakeGraph(runner);

      expect(graph.keys, containsAll(['app', 'website', 'mvc', 'http']));
      expect(packageNamed(graph, 'http').version, '1.2.3');
      expect(packageNamed(graph, 'http').source, hostedSource);
      expect(runner.calls.single, ['pub', 'deps', '--json']);
    });

    test('a root package reads directDependencies, not dependencies', () async {
      final runner = FakeDartProcessRunner('fake_dart', fakePubDepsJson);
      final graph = await _loadFakeGraph(runner);

      // app's combined `dependencies` includes `test` (a dev
      // dependency); its `directDependencies` (what this reader
      // actually uses) must not.
      final app = packageNamed(graph, 'app');
      expect(app.runtimeDependencies, isNot(contains('test')));
      expect(app.runtimeDependencies, contains('http'));
    });

    test('a non-root package reads dependencies', () async {
      final runner = FakeDartProcessRunner('fake_dart', fakePubDepsJson);
      final graph = await _loadFakeGraph(runner);

      expect(packageNamed(graph, 'flutter').runtimeDependencies, [
        'meta',
        'sky_engine',
      ]);
    });
  });

  group('resolveDependencyGraph: failures', () {
    test('throws CommandFailure on a non-zero exit', () async {
      expect(
        () => _loadFakeGraph(FailingDartProcessRunner()),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('throws CommandFailure on unparseable output', () async {
      expect(
        () => _loadFakeGraph(FakeDartProcessRunner('fake_dart', 'not json')),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('transitiveClosure', () {
    // Assigned in setUp/read throughout the tests, cleaned up in
    // tearDown — the standard package:test fixture-per-test pattern.
    // ignore: solid_lints/avoid_late_keyword
    late Map<String, GraphPackage> graph;

    setUp(() async {
      graph = await _loadFakeGraph(
        FakeDartProcessRunner('fake_dart', fakePubDepsJson),
      );
    });

    test('includes only what app actually depends on, transitively', () {
      final closure = transitiveClosure(graph, 'app');
      final names = closure.map((p) => p.name).toSet();

      expect(names, {'http', 'mvc', 'flutter', 'meta', 'sky_engine'});
    });

    test('excludes the app itself and unrelated workspace members', () {
      final closure = transitiveClosure(graph, 'app');
      final names = closure.map((p) => p.name).toSet();

      expect(names, isNot(contains('app')));
      expect(names, isNot(contains('website')));
    });

    test('excludes a dev-only direct dependency', () {
      final closure = transitiveClosure(graph, 'app');

      expect(closure.map((p) => p.name), isNot(contains('test')));
    });

    test('is sorted by name', () {
      final closure = transitiveClosure(graph, 'app');

      expect(
        closure.map((p) => p.name).toList(),
        closure.map((p) => p.name).toList()..sort(),
      );
    });

    test('a smaller app (website) gets a smaller closure', () {
      final closure = transitiveClosure(graph, 'website');

      expect(closure.map((p) => p.name).toSet(), {'http'});
    });

    test('throws CommandFailure for an unknown app package name', () {
      expect(
        () => transitiveClosure(graph, 'no_such_app'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });
}

/// Runs [resolveDependencyGraph] against `/repo` via [runner] — every
/// test in this file wants the exact same `repoRoot`/`dartExecutable`,
/// varying only the runner.
Future<Map<String, GraphPackage>> _loadFakeGraph(ProcessRunner runner) =>
    resolveDependencyGraph(
      runner: runner,
      repoRoot: '/repo',
      dartExecutable: 'fake_dart',
    );
