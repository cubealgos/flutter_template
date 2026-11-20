import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/yaml_field.dart';
import 'package:yaml/yaml.dart';

/// One keyed exception from `tool/licence-exceptions.yaml`: a deliberate
/// allowance for one package's one licence, never a blanket allowance for
/// the package. Keyed on (`package`, `licence`) together — per the policy
/// document, "an exception that survives the package relicensing is a
/// hole, not an exception" — so if the package's detected licence ever
/// changes, this entry no longer matches and the gate re-refuses it.
class LicenceException {
  /// Creates an exception entry.
  const LicenceException({
    required this.package,
    required this.licence,
    required this.reason,
    this.scope = 'all',
  });

  /// The pub.dev package name this exception covers.
  final String package;

  /// The canonical SPDX identifier (matching `licence_policy.dart`'s
  /// vocabulary) this exception covers — the package's detected licence
  /// must equal this exactly.
  final String licence;

  /// Why the exception was granted, printed on every run so it never
  /// reads as a silent allow-list entry.
  final String reason;

  /// A free-text scope note (e.g. `dev`, `all`) — recorded for the reader,
  /// not enforced by this tool (this workspace doesn't yet distinguish
  /// dev-only from runtime dependency graphs in `pubspec.lock`).
  final String scope;

  /// True if this exception covers package `packageName`'s detected
  /// licence `licenceId`.
  bool covers(String packageName, String licenceId) =>
      package == packageName && licence == licenceId;

  @override
  String toString() => '$package ($licence, scope: $scope): $reason';
}

/// Loads the keyed exception list from `<repoRoot>/tool/licence-exceptions.yaml`
/// (`path`). A missing file is not an error — it means no exceptions are
/// granted — but a present, malformed file is.
List<LicenceException> loadLicenceExceptions(String path) {
  final file = File(path);
  if (!file.existsSync()) return const <LicenceException>[];

  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    throw CommandFailure('$path is not valid YAML: $e');
  }
  if (doc == null || doc is! YamlMap || doc['exceptions'] == null) {
    return const <LicenceException>[];
  }
  if (doc['exceptions'] is! YamlList) {
    throw CommandFailure("$path: 'exceptions' must be a list.");
  }

  return [
    for (final raw in doc['exceptions'] as YamlList) _parseEntry(raw, path),
  ];
}

/// Parses one `exceptions:` list entry, throwing [CommandFailure] (naming
/// `path` for a useful message) on any missing or wrongly-typed field.
/// Factored out of [loadLicenceExceptions] to keep that function's own
/// branching low — this is where the entry-shape validation lives.
LicenceException _parseEntry(Object? raw, String path) {
  if (raw is! YamlMap) {
    throw CommandFailure('$path: every exceptions entry must be a map.');
  }
  var ctx = (path: path, entryNoun: 'an entry', context: null as String?);
  final package = requireYamlField(raw, 'package', ctx);
  ctx = (path: ctx.path, entryNoun: ctx.entryNoun, context: package);
  final licence = requireYamlField(raw, 'licence', ctx);
  final reason = requireYamlField(raw, 'reason', ctx);
  final scope = raw['scope'];
  if (scope != null && scope is! String) {
    throw CommandFailure(
      "$path: entry for '$package' has a non-string 'scope'.",
    );
  }

  return LicenceException(
    package: package,
    licence: licence,
    reason: reason,
    scope: (scope as String?) ?? 'all',
  );
}
