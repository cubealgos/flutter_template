import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/advisory_severity.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/licence_check_command.dart';
import 'package:tooling/src/locked_package.dart';
import 'package:tooling/src/osv_client.dart';
import 'package:tooling/src/package_advisory.dart';
import 'package:tooling/src/vuln_exception.dart';

/// Checks every resolved hosted package against the public OSV database and
/// fails on critical and high advisories no unexpired exception covers.
///
/// Severity rule: see `assessSeverity` in `advisory_severity.dart`. An
/// advisory whose severity cannot be read counts as high. Medium and low
/// advisories are listed but never fail the check.
///
/// Exceptions live in `tool/vuln-exceptions.yaml` (package, advisory,
/// reason, date, expires). Every one is printed on every run, and an
/// expired one fails the check on its own.
class VulnCheckCommand {
  /// Creates a command rooted at [repoRoot] using [client] (injected in
  /// tests). [today] is injectable so expiry is testable.
  VulnCheckCommand({
    required this.repoRoot,
    required this.client,
    DateTime Function()? today,
    this.exceptionsPath = 'tool/vuln-exceptions.yaml',
    this.lockfilePaths = defaultLockfilePaths,
  }) : _today = today ?? DateTime.now;

  /// The repo root every relative path resolves against.
  final String repoRoot;

  /// The OSV client.
  final OsvClient client;

  /// The exceptions file, relative to [repoRoot].
  final String exceptionsPath;

  /// Lockfiles to walk, relative to [repoRoot].
  final List<String> lockfilePaths;

  final DateTime Function() _today;

  /// Runs the check and returns the exit code: 0 if nothing blocks, 1 if a
  /// critical/high advisory is uncovered or an exception has expired.
  Future<int> run({
    void Function(String) out = _defaultOut,
    void Function(String) err = _defaultErr,
  }) async {
    final exceptions = loadVulnExceptions(p.join(repoRoot, exceptionsPath));
    final today = _today();
    final expired = exceptions.where((e) => e.isExpiredOn(today)).toList();
    final active = exceptions.where((e) => !e.isExpiredOn(today)).toList();

    final locked = _lockedVersions();
    final queries = <PubPackageVersion>[
      for (final entry in locked.entries)
        for (final version in entry.value) (name: entry.key, version: version),
    ];
    final idLists = await client.advisoryIdsFor(queries);

    final findings = <PackageAdvisory>[];
    for (var i = 0; i < queries.length; i++) {
      for (final id in idLists[i]) {
        final record = await client.vulnerability(id);
        if (record['withdrawn'] != null) continue;
        findings.add(_finding(queries[i], id, record, active));
      }
    }

    _report(queries.length, findings, (active: active, expired: expired), out);

    final blocking = findings.where((f) => f.blocks).toList();
    if (blocking.isNotEmpty || expired.isNotEmpty) {
      err(
        'vuln_check: failed — ${blocking.length} critical/high '
        'advisor${blocking.length == 1 ? 'y' : 'ies'} without an exception, '
        '${expired.length} expired exception(s).',
      );

      return 1;
    }

    return 0;
  }

  PackageAdvisory _finding(
    PubPackageVersion query,
    String id,
    Map<String, dynamic> record,
    List<VulnException> active,
  ) {
    final aliases = <String>[
      if (record['aliases'] is List)
        ...(record['aliases'] as List).cast<String>(),
    ];
    final summary = record['summary'];
    VulnException? matched;
    for (final e in active) {
      if (e.covers(query.name, [id, ...aliases])) matched = e;
    }

    return PackageAdvisory(
      package: query.name,
      version: query.version,
      id: id,
      aliases: aliases,
      summary: summary is String ? summary.trim() : '',
      assessment: assessSeverity(record),
      exception: matched,
    );
  }

  Map<String, Set<String>> _lockedVersions() {
    final versions = <String, Set<String>>{};
    var found = 0;
    for (final lockfile in lockfilePaths) {
      final path = p.join(repoRoot, lockfile);
      if (!File(path).existsSync()) continue;
      found++;
      for (final locked in hostedPackagesFromLockfile(path)) {
        versions.putIfAbsent(locked.name, () => <String>{}).add(locked.version);
      }
    }
    if (found == 0) {
      throw CommandFailure(
        'vuln_check: none of ${lockfilePaths.join(', ')} exists under '
        '$repoRoot.',
      );
    }

    return Map.fromEntries(
      versions.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _report(
    int checked,
    List<PackageAdvisory> findings,
    ({List<VulnException> active, List<VulnException> expired}) exceptions,
    void Function(String) out,
  ) {
    final (:active, :expired) = exceptions;
    final blocking = findings.where((f) => f.blocks).toList();
    final excepted = findings.where((f) => f.exception != null).toList();
    final below = findings
        .where((f) => !f.assessment.severity.blocksRelease)
        .toList();
    out(
      'vuln_check: $checked package version(s) checked against OSV — '
      '${findings.length} advisor${findings.length == 1 ? 'y' : 'ies'}: '
      '${blocking.length} blocking, ${excepted.length} excepted, '
      '${below.length} below threshold.',
    );

    out('');
    out(
      active.isEmpty
          ? 'Active exceptions: none.'
          : 'Active exceptions (${active.length}):',
    );
    for (final e in active) {
      out('  - $e');
    }
    if (expired.isNotEmpty) {
      out('');
      out('EXPIRED exceptions (${expired.length}) — renew or remove:');
      for (final e in expired) {
        out('  - $e');
      }
    }
    _section('Blocking advisories', blocking, out);
    _section('Excepted advisories', excepted, out, suffix: true);
    _section('Below threshold (medium/low, informational)', below, out);
  }

  void _section(
    String heading,
    List<PackageAdvisory> items,
    void Function(String) out, {
    bool suffix = false,
  }) {
    if (items.isEmpty) return;
    out('');
    out('$heading:');
    for (final f in items) {
      out('  - $f${suffix ? ' (via ${f.exception})' : ''}');
    }
  }

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);
}
