/// A small `dart pub deps --json` fixture, shaped like this workspace's
/// real graph but tiny: `app` (a `rootSource`-app-like member) depends on
/// `http` (hosted), `mvc` (a first-party `rootSource` member, itself
/// depending on `flutter`) and `flutter` (an `sdkSource` member depending
/// on `meta` and `sky_engine`); `app` also dev-depends on `test`, and an
/// unrelated `website` root member depends on `http` too — both there to
/// prove `transitiveClosure` scopes to one app and never dev deps.
///
/// Shared by `dependency_graph_test.dart`, `sbom_command_test.dart` and
/// `licence_bundle_command_test.dart` so all three exercise the exact
/// same shape.
const Map<String, Object?> fakePubDepsJson = {
  'root': 'example_app_workspace',
  'packages': [
    {
      'name': 'app',
      'version': '1.0.0+1',
      'kind': 'root',
      'source': 'root',
      'dependencies': <String>['http', 'mvc', 'flutter', 'test'],
      'directDependencies': <String>['http', 'mvc', 'flutter'],
      'devDependencies': <String>['test'],
    },
    {
      'name': 'website',
      'version': '1.0.0',
      'kind': 'root',
      'source': 'root',
      'dependencies': <String>['http'],
      'directDependencies': <String>['http'],
      'devDependencies': <String>[],
    },
    {
      'name': 'mvc',
      'version': '0.0.0',
      'kind': 'root',
      'source': 'root',
      'dependencies': <String>['flutter'],
      'directDependencies': <String>['flutter'],
      'devDependencies': <String>[],
    },
    {
      'name': 'http',
      'version': '1.2.3',
      'kind': 'transitive',
      'source': 'hosted',
      'dependencies': <String>[],
    },
    {
      'name': 'test',
      'version': '1.9.0',
      'kind': 'dev',
      'source': 'hosted',
      'dependencies': <String>[],
    },
    {
      'name': 'meta',
      'version': '1.16.0',
      'kind': 'transitive',
      'source': 'hosted',
      'dependencies': <String>[],
    },
    {
      'name': 'flutter',
      'version': '0.0.0',
      'kind': 'transitive',
      'source': 'sdk',
      'dependencies': <String>['meta', 'sky_engine'],
    },
    {
      'name': 'sky_engine',
      'version': '0.0.0',
      'kind': 'transitive',
      'source': 'sdk',
      'dependencies': <String>[],
    },
  ],
  'sdks': [
    {'name': 'Dart', 'version': '3.13.4'},
    {'name': 'Flutter', 'version': '3.47.5'},
  ],
};
