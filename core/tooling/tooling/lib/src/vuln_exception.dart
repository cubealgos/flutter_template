import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/yaml_field.dart';
import 'package:yaml/yaml.dart';

final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// One keyed exception from `tool/vuln-exceptions.yaml`: a deliberate,
/// time-boxed acceptance of one advisory against one package. Keyed on
/// (`package`, `advisory`) so it never blankets the package, and it
/// *expires*: past [expires] it stops covering anything and the gate fails
/// until someone renews or removes it.
class VulnException {
  /// Creates an exception entry.
  const VulnException({
    required this.package,
    required this.advisory,
    required this.reason,
    required this.date,
    required this.expires,
  });

  /// The pub.dev package name.
  final String package;

  /// The advisory id (e.g. `GHSA-xxxx-xxxx-xxxx`); an alias such as a CVE id
  /// also matches.
  final String advisory;

  /// Why the advisory is acceptable, printed on every run.
  final String reason;

  /// The date the exception was granted (`YYYY-MM-DD`).
  final DateTime date;

  /// The last day the exception applies (`YYYY-MM-DD`, inclusive).
  final DateTime expires;

  /// True if [today] is after [expires].
  bool isExpiredOn(DateTime today) {
    final day = DateTime.utc(today.year, today.month, today.day);

    return day.isAfter(expires);
  }

  /// True if this exception covers [packageName] and any of [ids].
  bool covers(String packageName, Iterable<String> ids) =>
      package == packageName && ids.contains(advisory);

  @override
  String toString() =>
      '$package $advisory (granted ${_fmt(date)}, expires ${_fmt(expires)}): '
      '$reason';

  static String _fmt(DateTime d) => d.toIso8601String().split('T').first;
}

/// Loads `tool/vuln-exceptions.yaml`. A missing file means no exceptions; a
/// present but malformed file is a [CommandFailure].
List<VulnException> loadVulnExceptions(String path) {
  final file = File(path);
  if (!file.existsSync()) return const <VulnException>[];

  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    throw CommandFailure('$path is not valid YAML: $e');
  }
  if (doc == null || doc is! YamlMap || doc['exceptions'] == null) {
    return const <VulnException>[];
  }
  if (doc['exceptions'] is! YamlList) {
    throw CommandFailure("$path: 'exceptions' must be a list.");
  }

  return [
    for (final raw in doc['exceptions'] as YamlList) _parseEntry(raw, path),
  ];
}

VulnException _parseEntry(Object? raw, String path) {
  if (raw is! YamlMap) {
    throw CommandFailure('$path: every exceptions entry must be a map.');
  }
  var ctx = (path: path, entryNoun: 'an entry', context: null as String?);
  final package = requireYamlField(raw, 'package', ctx);
  ctx = (path: path, entryNoun: 'an entry', context: package);
  final advisory = requireYamlField(raw, 'advisory', ctx);
  final reason = requireYamlField(raw, 'reason', ctx);
  final date = _parseDate(requireYamlField(raw, 'date', ctx), 'date', ctx);
  final expires = _parseDate(
    requireYamlField(raw, 'expires', ctx),
    'expires',
    ctx,
  );
  if (expires.isBefore(date)) {
    throw CommandFailure(
      "$path: entry for '$package' ($advisory) expires before it was granted.",
    );
  }

  return VulnException(
    package: package,
    advisory: advisory,
    reason: reason,
    date: date,
    expires: expires,
  );
}

DateTime _parseDate(String text, String field, YamlEntryContext ctx) {
  final parsed = _isoDate.hasMatch(text)
      ? DateTime.tryParse('${text}T00:00:00Z')
      : null;
  if (parsed == null) {
    throw CommandFailure(
      "${ctx.path}: entry for '${ctx.context}' has an invalid '$field' "
      "('$text'; use YYYY-MM-DD, quoted).",
    );
  }

  return parsed;
}
