/// `source` values `dart pub deps --json` reports for a resolved package —
/// see [GraphPackage.source].
const String hostedSource = 'hosted';

/// A workspace member, resolved via a `path` (or, for the workspace root
/// itself, `root`) dependency — see [GraphPackage.source].
const String rootSource = 'root';

/// Shipped inside the Flutter/Dart SDK itself (`flutter`, `sky_engine`,
/// `flutter_web_plugins`, …) rather than fetched from pub.dev — see
/// [GraphPackage.source].
const String sdkSource = 'sdk';

/// One resolved package node in the workspace's pub dependency graph, as
/// reported by `dart pub deps --json` (see `dependency_graph.dart`'s
/// `resolveDependencyGraph`).
class GraphPackage {
  /// Creates a graph node.
  const GraphPackage({
    required this.name,
    required this.version,
    required this.source,
    required this.runtimeDependencies,
  });

  /// The pub.dev package name.
  final String name;

  /// The resolved version. For a [rootSource] package this is whatever
  /// its own `pubspec.yaml` declares (`0.0.0` if it declares none — pub's
  /// own default, not a placeholder this reader invents).
  final String version;

  /// [hostedSource], [rootSource] or [sdkSource].
  final String source;

  /// This package's own direct **runtime** dependencies only.
  ///
  /// For a [rootSource] package that is deliberately
  /// `directDependencies`, never `dart pub deps --json`'s own combined
  /// `dependencies` list for a root node, which folds `dev_dependencies`
  /// in too (verified by hand against this workspace's own graph: e.g.
  /// `core/architecture/mvc`'s root node lists `flutter_test` and
  /// `very_good_analysis` in `dependencies` alongside `flutter`/
  /// `go_router`/`url_launcher`, but only the latter three in
  /// `directDependencies`). For a [hostedSource] or [sdkSource] package,
  /// pub never resolves *its* dev dependencies at all — its own
  /// `dependencies` list already is its runtime-only direct deps, so
  /// either field would do; `dependencies` is what's read.
  final List<String> runtimeDependencies;
}
