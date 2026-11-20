import 'package:yaml/yaml.dart';

/// Rewrites a workspace-member pubspec.yaml into a standalone manifest
/// suitable for Appwrite's server-side `dart pub get`: drops
/// `resolution: workspace` (which only resolves inside this workspace's own
/// `pub get`, and fails on the server, where only the function's own folder
/// is uploaded), pins every hosted dependency to the exact version the
/// workspace's `pubspec.lock` resolved (so what deploys is exactly what was
/// tested locally, not whatever the server's own `dart pub get` happens to
/// resolve on deploy day), and repoints every path dependency at
/// `<vendorPrefix>/<name>` inside the deployment bundle.
///
/// Drops `dev_dependencies` entirely: the server only ever runs
/// `dart pub get` then AOT-compiles the entrypoint, never `dart test`.
class PubspecRewriter {
  /// Creates a rewriter (stateless — kept as a class for a stable,
  /// mockable seam even though it holds no fields).
  const PubspecRewriter();

  /// Rewrites [originalYaml] (a package's pubspec.yaml contents), pinning
  /// hosted dependencies from [lockedVersions] and pointing every path
  /// dependency at `<vendorPrefix>/<name>`.
  ///
  /// Throws a [StateError] if a hosted dependency has no entry in
  /// [lockedVersions] — that means `dart pub get` hasn't been run at the
  /// repo root, so there is no lockfile to pin from.
  String rewrite({
    required String originalYaml,
    required Map<String, String> lockedVersions,
    required String vendorPrefix,
  }) {
    final doc = loadYaml(originalYaml) as YamlMap;
    final name = doc['name'] as String;
    final environment = doc['environment'] as YamlMap;
    final sdkConstraint = environment['sdk'] as String;
    final dependencies = doc['dependencies'] as YamlMap?;

    final buffer = StringBuffer()
      ..writeln('name: $name')
      ..writeln('publish_to: none')
      ..writeln()
      ..writeln('environment:')
      ..writeln('  sdk: $sdkConstraint')
      ..writeln();
    _writeDependencies(
      buffer,
      dependencies: dependencies,
      lockedVersions: lockedVersions,
      vendorPrefix: vendorPrefix,
    );

    return buffer.toString();
  }

  void _writeDependencies(
    StringBuffer buffer, {
    required YamlMap? dependencies,
    required Map<String, String> lockedVersions,
    required String vendorPrefix,
  }) {
    if (dependencies == null || dependencies.isEmpty) {
      buffer.writeln('dependencies: {}');

      return;
    }

    buffer.writeln('dependencies:');
    for (final entry in dependencies.entries) {
      final depName = entry.key as String;
      final value = entry.value;
      if (value is YamlMap && value.containsKey('path')) {
        buffer
          ..writeln('  $depName:')
          ..writeln('    path: $vendorPrefix/$depName');
        continue;
      }

      final version = lockedVersions[depName];
      if (version == null) {
        throw StateError(
          'No locked version found for hosted dependency "$depName" - run '
          '`dart pub get` at the repo root first.',
        );
      }
      buffer.writeln('  $depName: $version');
    }
  }
}
