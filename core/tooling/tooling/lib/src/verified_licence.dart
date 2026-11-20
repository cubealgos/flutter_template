import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/yaml_field.dart';
import 'package:yaml/yaml.dart';

/// A hand-verified licence for one package at one exact resolved version —
/// used only as a last resort, when pub.dev reports no recognisable
/// licence at all (its `license:` tags are absent, `unknown`, or an
/// identifier this workspace doesn't recognise — see
/// `PackageLicences.spdxCandidates` and `licence_check_command.dart`'s
/// classification). Unlike `LicenceException` this never overrides a
/// licence pub.dev *did* detect, and the [licence] itself still has to be
/// on `licence_policy.dart`'s `allowedLicences` — a verified GPL is still
/// denied. Keyed on the exact [version]: an upgrade doesn't carry the
/// verification forward, so the gate re-refuses until someone reads the
/// new version's LICENSE file and records a fresh entry.
class VerifiedLicence {
  /// Creates a verified-licence entry.
  const VerifiedLicence({
    required this.package,
    required this.version,
    required this.licence,
    required this.reason,
  });

  /// The pub.dev package name this verification covers.
  final String package;

  /// The exact resolved version this verification covers.
  final String version;

  /// The canonical SPDX identifier (matching `licence_policy.dart`'s
  /// vocabulary) a human read directly out of the package's own LICENSE
  /// file, since pub.dev's own detector couldn't.
  final String licence;

  /// Why pub.dev's detection missed it, and where the human looked —
  /// printed on every run so this never reads as a silent allow-list
  /// entry.
  final String reason;

  /// True if this entry covers package `packageName` at exactly
  /// `resolvedVersion`.
  bool covers(String packageName, String resolvedVersion) =>
      package == packageName && version == resolvedVersion;

  @override
  String toString() => '$package $version ($licence): $reason';
}

/// Loads the `verified:` list from `<repoRoot>/tool/licence-exceptions.yaml`
/// (`path` — the same file `loadLicenceExceptions` reads its `exceptions:`
/// list from). A missing file, or a file with no `verified:` key, yields
/// no entries — only a present-but-malformed one is an error.
List<VerifiedLicence> loadVerifiedLicences(String path) {
  final file = File(path);
  if (!file.existsSync()) return const <VerifiedLicence>[];

  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    throw CommandFailure('$path is not valid YAML: $e');
  }
  if (doc == null || doc is! YamlMap || doc['verified'] == null) {
    return const <VerifiedLicence>[];
  }
  if (doc['verified'] is! YamlList) {
    throw CommandFailure("$path: 'verified' must be a list.");
  }

  return [
    for (final raw in doc['verified'] as YamlList)
      _parseVerifiedEntry(raw, path),
  ];
}

/// Parses one `verified:` list entry, throwing [CommandFailure] (naming
/// `path` for a useful message) on any missing or wrongly-typed field.
/// Factored out of [loadVerifiedLicences] to keep that function's own
/// branching low — this is where the entry-shape validation lives.
VerifiedLicence _parseVerifiedEntry(Object? raw, String path) {
  if (raw is! YamlMap) {
    throw CommandFailure('$path: every verified entry must be a map.');
  }
  var ctx = (
    path: path,
    entryNoun: 'a verified entry',
    context: null as String?,
  );
  final package = requireYamlField(raw, 'package', ctx);
  ctx = (path: ctx.path, entryNoun: ctx.entryNoun, context: package);
  final version = requireYamlField(raw, 'version', ctx);
  final licence = requireYamlField(raw, 'licence', ctx);
  final reason = requireYamlField(raw, 'reason', ctx);

  return VerifiedLicence(
    package: package,
    version: version,
    licence: licence,
    reason: reason,
  );
}
