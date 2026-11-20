import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:yaml/yaml.dart';

/// The `pkg:generic/<namespace>/...` purl namespace `tooling:sbom` gives
/// every first-party workspace component, and the app's own metadata
/// component (see `sbom_command.dart`'s `_firstPartyComponent` and
/// `cyclonedx_document.dart`'s `appPurl`): the workspace root
/// `pubspec.yaml`'s own top-level `name:`, with a trailing `_workspace`
/// suffix stripped.
///
/// This mirrors `rename_identity.dart`'s `OldIdentity.templateToken`
/// derivation exactly (same suffix-stripping rule, applied to the same
/// field), but reads it directly off whatever clone is actually running
/// `tooling:sbom` rather than assuming the template's own placeholder
/// name — a purl namespace that instead hard-coded the placeholder
/// wouldn't change after a clone renamed itself, and would read as a
/// leftover reference to the old name (`rename_leftover_check.dart`
/// case-insensitively greps every source file for exactly that token).
String workspacePurlNamespace(String repoRoot) {
  final pubspecFile = File(p.join(repoRoot, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    throw CommandFailure('${pubspecFile.path} not found.');
  }
  final doc = loadYaml(pubspecFile.readAsStringSync());
  final name = doc is YamlMap ? doc['name'] as String? : null;
  if (name == null) {
    throw CommandFailure('${pubspecFile.path} has no top-level "name:".');
  }
  const suffix = '_workspace';

  return name.endsWith(suffix)
      ? name.substring(0, name.length - suffix.length)
      : name;
}
