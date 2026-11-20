import 'package:yaml/yaml.dart';

/// The exact resolved version of every hosted (pub.dev) dependency in the
/// workspace's `pubspec.lock` — what `PubspecRewriter` pins a deployed
/// function's hosted dependencies to, so what ships is exactly what was
/// tested locally rather than whatever the server's own `dart pub get`
/// happens to resolve on deploy day.
class PubspecLock {
  /// Wraps an already-parsed set of hosted package versions.
  const PubspecLock(this.hostedVersions);

  /// Parses a workspace `pubspec.lock` file's contents.
  factory PubspecLock.parse(String yamlText) {
    final doc = loadYaml(yamlText) as YamlMap;
    final packages = doc['packages'] as YamlMap?;
    final versions = <String, String>{};
    if (packages != null) {
      for (final entry in packages.entries) {
        final name = entry.key as String;
        final info = entry.value as YamlMap;
        if (info['source'] == 'hosted') {
          versions[name] = info['version'] as String;
        }
      }
    }

    return PubspecLock(versions);
  }

  /// Package name -> exact resolved version, for every hosted dependency.
  final Map<String, String> hostedVersions;
}
