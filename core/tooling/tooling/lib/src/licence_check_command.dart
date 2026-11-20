import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/licence_exception.dart';
import 'package:tooling/src/licence_policy.dart';
import 'package:tooling/src/licence_verdict.dart';
import 'package:tooling/src/locked_package.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';
import 'package:tooling/src/verified_licence.dart';

/// The lockfiles `licence_check` walks by default, relative to the repo
/// root: the workspace's own resolution, plus `core/architecture/mvc_lints`' —
/// that package deliberately has its own, isolated pub resolution (never
/// a workspace member; see its `pubspec.yaml`) and so is invisible to the
/// root lockfile.
const List<String> defaultLockfilePaths = <String>[
  'pubspec.lock',
  'core/architecture/mvc_lints/pubspec.lock',
];

/// The keyed exceptions and hand-verified detection-gap overrides loaded
/// from `tool/licence-exceptions.yaml`, threaded through classification
/// and reporting as one unit.
typedef PolicyOverrides = ({
  List<LicenceException> exceptions,
  List<VerifiedLicence> verified,
});

/// Walks the resolved dependency graph (every `source: hosted` package
/// across [lockfilePaths], relative to [repoRoot]) and classifies each
/// package's pub.dev-reported licence(s) against [allowedLicences] /
/// [deniedLicences] / the MPL-2.0 exception carve-out, using
/// `tool/licence-exceptions.yaml` for keyed exceptions and hand-verified
/// detection-gap overrides. Never fetches a package more than once, even
/// when it appears in multiple lockfiles.
class LicenceCheckCommand {
  /// Creates a command rooted at [repoRoot], using [client] to resolve
  /// licences (injected in tests) and checking [lockfilePaths] (relative
  /// to [repoRoot], default: [defaultLockfilePaths]).
  LicenceCheckCommand({
    required this.repoRoot,
    required this.client,
    this.exceptionsPath,
    this.lockfilePaths = defaultLockfilePaths,
  });

  /// The repo root every relative path is resolved against.
  final String repoRoot;

  /// The licence-resolving client (real or fake).
  final PubDevLicenceClient client;

  /// Path to the exceptions YAML file, relative to [repoRoot]. Defaults
  /// to `tool/licence-exceptions.yaml`.
  final String? exceptionsPath;

  /// Lockfile paths, relative to [repoRoot], to walk.
  final List<String> lockfilePaths;

  /// Runs the check, printing a report via [out]/[err], and returns the
  /// process exit code (`0` if every package is allowed, exempted or
  /// verified, `1` if any is denied).
  Future<int> run({
    void Function(String) out = _defaultOut,
    void Function(String) err = _defaultErr,
  }) async {
    final overrides = _loadOverrides();
    final versionsByPackage = _lockedVersionsByPackage();
    final verdicts = <PackageVerdict>[];
    for (final entry in versionsByPackage.entries) {
      // A package locked at several versions (across lockfiles) is judged
      // on the union of their tags.
      final tags = <String>{};
      for (final version in entry.value) {
        tags.addAll(
          (await client.licencesFor(entry.key, version)).rawTagSuffixes,
        );
      }
      final licences = PackageLicences(tags.toList());
      verdicts.add(_classify(entry.key, entry.value, licences, overrides));
    }

    _report(verdicts, overrides, out);

    final denied = verdicts.where((v) => v.verdict == LicenceVerdict.denied);
    if (denied.isNotEmpty) {
      err(
        'licence_check: ${denied.length} package(s) failed the licence '
        'gate: ${denied.map((v) => v.name).join(', ')}.',
      );

      return 1;
    }

    return 0;
  }

  PolicyOverrides _loadOverrides() {
    final exceptionsFile = p.join(
      repoRoot,
      exceptionsPath ?? 'tool/licence-exceptions.yaml',
    );

    return (
      exceptions: loadLicenceExceptions(exceptionsFile),
      verified: loadVerifiedLicences(exceptionsFile),
    );
  }

  /// Every `source: hosted` package name found across [lockfilePaths],
  /// mapped to the set of distinct resolved versions seen for it — sorted
  /// by name so the report and the fetch order are deterministic.
  Map<String, Set<String>> _lockedVersionsByPackage() {
    final versionsByPackage = <String, Set<String>>{};
    for (final lockfilePath in lockfilePaths) {
      final fullPath = p.join(repoRoot, lockfilePath);
      if (!File(fullPath).existsSync()) continue;
      for (final locked in hostedPackagesFromLockfile(fullPath)) {
        versionsByPackage
            .putIfAbsent(locked.name, () => <String>{})
            .add(locked.version);
      }
    }

    return Map.fromEntries(
      versionsByPackage.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  PackageVerdict _classify(
    String name,
    Set<String> versions,
    PackageLicences licences,
    PolicyOverrides overrides,
  ) {
    final candidates = licences.spdxCandidates;
    final allowed = _matchAllowed(name, versions, candidates);
    if (allowed != null) return allowed;

    final exempted = _matchException(
      name,
      versions,
      candidates,
      overrides.exceptions,
    );
    if (exempted != null) return exempted;

    // Detection-gap fallback only — never reached when pub.dev detected
    // something recognisable, even something denied.
    if (candidates.isEmpty) {
      final verified = _matchVerified(name, versions, overrides.verified);
      if (verified != null) return verified;
    }

    return PackageVerdict(
      name: name,
      versions: versions,
      licences: candidates.isEmpty ? licences.unrecognisedTags : candidates,
      verdict: LicenceVerdict.denied,
    );
  }

  PackageVerdict? _matchAllowed(
    String name,
    Set<String> versions,
    List<String> candidates,
  ) {
    for (final candidate in candidates) {
      if (!allowedLicences.contains(candidate)) continue;

      return PackageVerdict(
        name: name,
        versions: versions,
        licences: candidates,
        verdict: LicenceVerdict.allowed,
      );
    }

    return null;
  }

  PackageVerdict? _matchException(
    String name,
    Set<String> versions,
    List<String> candidates,
    List<LicenceException> exceptions,
  ) {
    for (final candidate in candidates) {
      for (final exception in exceptions) {
        if (!exception.covers(name, candidate)) continue;

        return PackageVerdict(
          name: name,
          versions: versions,
          licences: candidates,
          verdict: LicenceVerdict.exempted,
          matchedException: exception,
        );
      }
    }

    return null;
  }

  /// The verified licence itself still has to clear [allowedLicences] — a
  /// verified GPL stays denied.
  PackageVerdict? _matchVerified(
    String name,
    Set<String> versions,
    List<VerifiedLicence> verified,
  ) {
    for (final version in versions) {
      for (final entry in verified) {
        if (!entry.covers(name, version)) continue;
        if (!allowedLicences.contains(entry.licence)) continue;

        return PackageVerdict(
          name: name,
          versions: versions,
          licences: [entry.licence],
          verdict: LicenceVerdict.verified,
          matchedVerified: entry,
        );
      }
    }

    return null;
  }

  void _report(
    List<PackageVerdict> verdicts,
    PolicyOverrides overrides,
    void Function(String) out,
  ) {
    _reportSummary(verdicts, out);
    _reportOverrideList('Active exceptions', overrides.exceptions, out);
    _reportOverrideList(
      'Verified detection-gap overrides',
      overrides.verified,
      out,
    );
    _reportExempted(verdicts, out);
    _reportVerified(verdicts, out);
    _reportDenied(verdicts, out);
  }

  void _reportSummary(
    List<PackageVerdict> verdicts,
    void Function(String) out,
  ) {
    final counts = {
      for (final verdict in LicenceVerdict.values)
        verdict: verdicts.where((v) => v.verdict == verdict).length,
    };
    out(
      'licence_check: ${verdicts.length} hosted package(s) checked — '
      '${counts[LicenceVerdict.allowed]} allowed, '
      '${counts[LicenceVerdict.exempted]} exempted, '
      '${counts[LicenceVerdict.verified]} verified, '
      '${counts[LicenceVerdict.denied]} denied.',
    );
  }

  /// Prints [entries] (either the loaded exceptions or the loaded verified
  /// overrides) under [heading], unconditionally — every entry that
  /// exists, not just the ones a verdict actually matched, so this never
  /// reads as a silent allow-list.
  void _reportOverrideList(
    String heading,
    List<Object> entries,
    void Function(String) out,
  ) {
    out('');
    out(entries.isEmpty ? '$heading: none.' : '$heading (${entries.length}):');
    for (final entry in entries) {
      out('  - $entry');
    }
  }

  void _reportExempted(
    List<PackageVerdict> verdicts,
    void Function(String) out,
  ) {
    final exempted = verdicts.where(
      (v) => v.verdict == LicenceVerdict.exempted,
    );
    if (exempted.isEmpty) return;

    out('');
    out('Exempted packages:');
    for (final v in exempted) {
      out(
        '  - ${v.name} ${v.versions.join(', ')}: ${v.licences.join('/')} '
        '(via ${v.matchedException})',
      );
    }
  }

  void _reportVerified(
    List<PackageVerdict> verdicts,
    void Function(String) out,
  ) {
    final verified = verdicts.where(
      (v) => v.verdict == LicenceVerdict.verified,
    );
    if (verified.isEmpty) return;

    out('');
    out('Verified packages:');
    for (final v in verified) {
      out(
        '  - ${v.name} ${v.versions.join(', ')}: ${v.licences.join('/')} '
        '(via ${v.matchedVerified})',
      );
    }
  }

  void _reportDenied(List<PackageVerdict> verdicts, void Function(String) out) {
    final denied = verdicts.where((v) => v.verdict == LicenceVerdict.denied);
    if (denied.isEmpty) return;

    out('');
    out('Denied packages:');
    for (final v in denied) {
      final licenceText = v.licences.isEmpty
          ? '<no licence tag found>'
          : v.licences.join('/');
      out('  - ${v.name} ${v.versions.join(', ')}: $licenceText');
    }
  }

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);
}

/// The verdict for one resolved package, across every lockfile it was
/// found in.
class PackageVerdict {
  /// Creates a verdict.
  const PackageVerdict({
    required this.name,
    required this.versions,
    required this.licences,
    required this.verdict,
    this.matchedException,
    this.matchedVerified,
  });

  /// The pub.dev package name.
  final String name;

  /// Every distinct resolved version seen across the checked lockfiles.
  final Set<String> versions;

  /// The recognised SPDX candidate licences found for this package
  /// (`PackageLicences.spdxCandidates`) — empty if pub.dev reported
  /// nothing recognised.
  final List<String> licences;

  /// The policy outcome.
  final LicenceVerdict verdict;

  /// The exception that produced [LicenceVerdict.exempted], if any.
  final LicenceException? matchedException;

  /// The verified entry that produced [LicenceVerdict.verified], if any.
  final VerifiedLicence? matchedVerified;
}
