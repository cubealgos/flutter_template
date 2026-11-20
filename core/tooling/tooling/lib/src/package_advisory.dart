import 'package:tooling/src/advisory_severity.dart';
import 'package:tooling/src/vuln_exception.dart';

/// One advisory affecting one locked package version.
class PackageAdvisory {
  /// Creates a finding.
  const PackageAdvisory({
    required this.package,
    required this.version,
    required this.id,
    required this.aliases,
    required this.summary,
    required this.assessment,
    this.exception,
  });

  /// The affected package.
  final String package;

  /// The locked version.
  final String version;

  /// The advisory id as OSV lists it.
  final String id;

  /// Other ids for the same advisory (CVE, GHSA).
  final List<String> aliases;

  /// OSV's one-line summary (may be empty).
  final String summary;

  /// The classified severity.
  final SeverityAssessment assessment;

  /// The active exception covering this finding, if any.
  final VulnException? exception;

  /// True if this finding fails the gate.
  bool get blocks => assessment.severity.blocksRelease && exception == null;

  @override
  String toString() =>
      '$package $version: $id [${assessment.severity.name.toUpperCase()}'
      '${assessment.unrated ? ', unrated, assumed' : ''}]'
      '${summary.isEmpty ? '' : ' $summary'}'
      '${aliases.isEmpty ? '' : ' (also ${aliases.join(', ')})'}';
}
