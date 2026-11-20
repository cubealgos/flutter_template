import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:yaml/yaml.dart';

/// One `hosted` (pub.dev) entry from a `pubspec.lock`: a resolved,
/// third-party package the licence gate needs to check. Workspace members
/// (`source: path`) and SDK packages (`source: sdk`, e.g. `flutter`,
/// `sky_engine`) are never included — see [hostedPackagesFromLockfile].
class LockedPackage {
  /// Creates a locked hosted-package entry.
  const LockedPackage({required this.name, required this.version, this.sha256});

  /// The pub.dev package name.
  final String name;

  /// The resolved version string, as recorded in the lockfile.
  final String version;

  /// This entry's `description.sha256` field, if the lockfile recorded
  /// one (pub always writes one for a normal pub.dev resolution; `null`
  /// only for a hand-written or otherwise unusual lockfile). Read by
  /// `sbom_command.dart` for each component's CycloneDX `hashes` entry —
  /// `licence_check_command.dart` itself never uses this field.
  final String? sha256;

  @override
  String toString() => '$name $version';
}

/// Parses `path` (a `pubspec.lock`) and returns every `source: hosted`
/// package it resolves, skipping `path` (workspace-member and other local
/// path) and `sdk` (`flutter`, `sky_engine`, ...) entries — those are
/// never fetched from pub.dev and are out of scope for a third-party
/// licence gate. Throws [CommandFailure] if `path` doesn't exist or isn't
/// a valid lockfile.
List<LockedPackage> hostedPackagesFromLockfile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw CommandFailure('$path not found.');
  }

  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    throw CommandFailure('$path is not valid YAML: $e');
  }
  if (doc is! YamlMap || doc['packages'] is! YamlMap) {
    throw CommandFailure("$path has no top-level 'packages' map.");
  }

  final result = <LockedPackage>[];
  for (final entry in (doc['packages'] as YamlMap).entries) {
    final name = entry.key as String;
    final meta = entry.value;
    if (meta is! YamlMap || meta['source'] != 'hosted') continue;
    result.add(_hostedEntry(path, name, meta));
  }

  return result;
}

LockedPackage _hostedEntry(String path, String name, YamlMap meta) {
  final version = meta['version'];
  if (version is! String) {
    throw CommandFailure("$path: '$name' has no string version.");
  }
  final description = meta['description'];
  final sha256 = description is YamlMap ? description['sha256'] : null;

  return LockedPackage(
    name: name,
    version: version,
    sha256: sha256 is String ? sha256 : null,
  );
}
