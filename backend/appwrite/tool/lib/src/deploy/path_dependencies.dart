import 'package:yaml/yaml.dart';

/// Returns every `path:` dependency declared in [pubspecYaml]'s
/// `dependencies` section, as name -> the declared path string (relative to
/// wherever that pubspec.yaml lives). Ignores hosted and `dev_dependencies`
/// entries — only regular `dependencies` are ever vendored into a
/// deployment bundle.
Map<String, String> pathDependenciesOf(String pubspecYaml) {
  final doc = loadYaml(pubspecYaml) as YamlMap;
  final dependencies = doc['dependencies'] as YamlMap?;
  if (dependencies == null) return <String, String>{};

  final paths = <String, String>{};
  for (final entry in dependencies.entries) {
    final value = entry.value;
    if (value is YamlMap && value.containsKey('path')) {
      paths[entry.key as String] = value['path'] as String;
    }
  }

  return paths;
}
