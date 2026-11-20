import 'dart:collection';
import 'dart:convert';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/graph_package.dart';
import 'package:tooling/src/process_runner.dart';

/// Runs `dart pub deps --json` (via [runner], invoking [dartExecutable]
/// from [repoRoot]) and returns every package the workspace resolves,
/// keyed by name.
///
/// In a pub **workspace** (this repo: one shared `pubspec.lock` for every
/// `core/`, `backend/`, `packages/` and `apps/` member) `dart pub deps
/// --json` reports the *whole* workspace's graph regardless of which
/// member directory it's invoked from — every member appears as its own
/// [rootSource] node, each with its own `directDependencies`, alongside
/// one shared list of every hosted/sdk package resolved anywhere in the
/// workspace. That whole-workspace shape is exactly why
/// [transitiveClosure] exists: this function alone never scopes a result
/// to one app, it just parses what pub already reports.
Future<Map<String, GraphPackage>> resolveDependencyGraph({
  required ProcessRunner runner,
  required String repoRoot,
  required String dartExecutable,
}) async {
  final result = await runner.run(dartExecutable, [
    'pub',
    'deps',
    '--json',
  ], workingDirectory: repoRoot);
  if (result.exitCode != 0) {
    throw CommandFailure(
      'dart pub deps --json failed (exit ${result.exitCode}):\n'
      '${result.stdout}\n${result.stderr}',
    );
  }

  return _parseDependencyGraph(result.stdout as String);
}

Map<String, GraphPackage> _parseDependencyGraph(String stdout) {
  final Object? decoded;
  try {
    decoded = jsonDecode(stdout);
  } on FormatException catch (e) {
    throw CommandFailure('dart pub deps --json: unparseable output: $e');
  }
  if (decoded is! Map || decoded['packages'] is! List) {
    throw CommandFailure("dart pub deps --json: no top-level 'packages' list.");
  }

  final byName = <String, GraphPackage>{};
  for (final raw in decoded['packages'] as List) {
    final pkg = _parseGraphPackage(raw);
    if (pkg != null) byName[pkg.name] = pkg;
  }

  return byName;
}

GraphPackage? _parseGraphPackage(Object? raw) {
  if (raw is! Map) return null;
  final name = raw['name'];
  final version = raw['version'];
  final source = raw['source'];
  if (name is! String || version is! String || source is! String) {
    return null;
  }
  final directKey = source == rootSource
      ? 'directDependencies'
      : 'dependencies';
  final direct = raw[directKey];

  return GraphPackage(
    name: name,
    version: version,
    source: source,
    runtimeDependencies: direct is List ? direct.cast<String>() : const [],
  );
}

/// Computes the transitive **runtime** dependency closure of
/// [appPackageName] within [graph] (as returned by
/// [resolveDependencyGraph]): a breadth-first walk seeded at that
/// package's own [GraphPackage.runtimeDependencies], following each
/// visited package's [GraphPackage.runtimeDependencies] in turn.
///
/// [appPackageName] itself is never included in the result — only what it
/// depends on, directly or transitively. Every result is sorted by name
/// for deterministic output (SBOM/licence-bundle generation, both callers
/// of this function, both need that).
///
/// This — rather than a hand-rolled walk of the workspace's own
/// `pubspec.yaml` dependency declarations, or the flat, workspace-wide
/// package list `pubspec.lock` itself carries — is what actually scopes
/// the result to one app: `pubspec.lock` alone doesn't distinguish which
/// resolved package belongs to which workspace member's own closure, only
/// `dart pub deps --json`'s per-package `directDependencies` do.
List<GraphPackage> transitiveClosure(
  Map<String, GraphPackage> graph,
  String appPackageName,
) {
  final app = graph[appPackageName];
  if (app == null) {
    throw CommandFailure(
      "dart pub deps --json: no package named '$appPackageName' in the "
      'resolved graph.',
    );
  }

  final visited = <String>{};
  final closure = <GraphPackage>[];
  final queue = Queue<String>.of(app.runtimeDependencies);
  while (queue.isNotEmpty) {
    final name = queue.removeFirst();
    if (!visited.add(name)) continue;
    final pkg = graph[name];
    if (pkg == null) continue;
    closure.add(pkg);
    queue.addAll(pkg.runtimeDependencies);
  }

  return closure..sort((a, b) => a.name.compareTo(b.name));
}
