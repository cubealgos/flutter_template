import 'package:tooling/src/cvss3.dart';

/// How serious an advisory is, ordered so `index` comparison works.
enum AdvisorySeverity {
  /// A CVSS score of 0, or a label this tool reads as "none".
  none,

  /// CVSS 0.1-3.9, or the label `LOW`.
  low,

  /// CVSS 4.0-6.9, or the labels `MODERATE`/`MEDIUM`.
  medium,

  /// CVSS 7.0-8.9, or the label `HIGH`.
  high,

  /// CVSS 9.0-10.0, or the label `CRITICAL`.
  critical;

  /// True if an advisory at this severity blocks a release.
  bool get blocksRelease => index >= AdvisorySeverity.high.index;
}

/// An advisory's severity plus whether it could actually be read.
class SeverityAssessment {
  /// Creates an assessment.
  const SeverityAssessment(this.severity, {required this.unrated});

  /// The level used for the gate. Fail-safe: [unrated] advisories are
  /// reported as [AdvisorySeverity.high].
  final AdvisorySeverity severity;

  /// True if OSV carried no severity this tool could parse, so [severity]
  /// is the fail-safe default rather than a reading.
  final bool unrated;

  @override
  String toString() => unrated
      ? '${severity.name.toUpperCase()} (unrated, assumed)'
      : severity.name.toUpperCase();
}

/// Classifies one OSV vulnerability record (the JSON of `GET /v1/vulns/<id>`).
///
/// The rule, in full: collect every severity signal that parses, take the
/// highest, and if there is none treat the advisory as `high`.
///
/// 1. Each `severity[]` entry of type `CVSS_V3`/`CVSS_V3.0`/`CVSS_V3.1`
///    whose `score` is a CVSS v3 vector is scored with the CVSS v3.1 base
///    formula and mapped to a level (>=9.0 critical, >=7.0 high, >=4.0
///    medium, >0 low). A bare number in `score` is read as the score.
/// 2. The text labels `database_specific.severity` (GitHub advisories use
///    `LOW`/`MODERATE`/`HIGH`/`CRITICAL`) and the same field under each
///    `affected[]` entry's `database_specific`/`ecosystem_specific`.
/// 3. CVSS v2 and v4 vectors are not scored; they count only through the
///    labels above.
///
/// Taking the highest means a low-rated label never hides a high CVSS score.
SeverityAssessment assessSeverity(Map<String, dynamic> vuln) {
  final found = <AdvisorySeverity>[
    ..._cvssLevels(vuln['severity']),
    ..._labelLevels(vuln['database_specific']),
  ];
  final affected = vuln['affected'];
  if (affected is List) {
    for (final entry in affected.whereType<Map<String, dynamic>>()) {
      found
        ..addAll(_labelLevels(entry['database_specific']))
        ..addAll(_labelLevels(entry['ecosystem_specific']));
    }
  }

  if (found.isEmpty) {
    return const SeverityAssessment(AdvisorySeverity.high, unrated: true);
  }
  final highest = found.reduce((a, b) => a.index >= b.index ? a : b);

  return SeverityAssessment(highest, unrated: false);
}

Iterable<AdvisorySeverity> _cvssLevels(Object? severities) sync* {
  if (severities is! List) return;
  for (final entry in severities.whereType<Map<String, dynamic>>()) {
    final score = entry['score'];
    if (score is! String || !'${entry['type']}'.startsWith('CVSS_V3')) {
      continue;
    }
    final value = cvss3BaseScore(score) ?? double.tryParse(score);
    if (value != null) yield severityForScore(value);
  }
}

// A flat label table; its branches are the labels, not logic.
// ignore: solid_lints/cyclomatic_complexity
Iterable<AdvisorySeverity> _labelLevels(Object? holder) sync* {
  if (holder is! Map) return;
  final label = holder['severity'];
  if (label is! String) return;
  final parsed = switch (label.trim().toUpperCase()) {
    'CRITICAL' => AdvisorySeverity.critical,
    'HIGH' => AdvisorySeverity.high,
    'MODERATE' || 'MEDIUM' => AdvisorySeverity.medium,
    'LOW' => AdvisorySeverity.low,
    'NONE' => AdvisorySeverity.none,
    _ => null,
  };
  if (parsed != null) yield parsed;
}

const double _criticalFrom = 9;
const double _highFrom = 7;
const double _mediumFrom = 4;

/// Maps a CVSS base score to its qualitative level (CVSS v3.1 section 5).
AdvisorySeverity severityForScore(double score) {
  if (score >= _criticalFrom) return AdvisorySeverity.critical;
  if (score >= _highFrom) return AdvisorySeverity.high;
  if (score >= _mediumFrom) return AdvisorySeverity.medium;
  if (score > 0) return AdvisorySeverity.low;

  return AdvisorySeverity.none;
}
