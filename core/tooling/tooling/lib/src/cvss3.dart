import 'dart:math';

// The CVSS v3.1 specification's own weights and formula constants; naming
// each one would only obscure the published tables they come from.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/cyclomatic_complexity

const Map<String, double> _attackVector = {
  'N': 0.85,
  'A': 0.62,
  'L': 0.55,
  'P': 0.2,
};
const Map<String, double> _attackComplexity = {'L': 0.77, 'H': 0.44};
const Map<String, double> _userInteraction = {'N': 0.85, 'R': 0.62};
const Map<String, double> _cia = {'H': 0.56, 'L': 0.22, 'N': 0.0};

/// The CVSS v3.0/v3.1 base score of [vector] (e.g.
/// `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`), or null if it is not a
/// well-formed v3 vector.
double? cvss3BaseScore(String vector) {
  final metrics = _parseMetrics(vector);
  if (metrics == null) return null;
  final scopeChanged = metrics['S'] == 'C';
  if (!scopeChanged && metrics['S'] != 'U') return null;

  final av = _attackVector[metrics['AV']];
  final ac = _attackComplexity[metrics['AC']];
  final ui = _userInteraction[metrics['UI']];
  final c = _cia[metrics['C']];
  final i = _cia[metrics['I']];
  final a = _cia[metrics['A']];
  final pr = switch (metrics['PR']) {
    'N' => 0.85,
    'L' => scopeChanged ? 0.68 : 0.62,
    'H' => scopeChanged ? 0.5 : 0.27,
    _ => null,
  };
  if (av == null ||
      ac == null ||
      ui == null ||
      c == null ||
      i == null ||
      a == null ||
      pr == null) {
    return null;
  }

  final iss = 1 - (1 - c) * (1 - i) * (1 - a);
  final impact = scopeChanged
      ? 7.52 * (iss - 0.029) - 3.25 * pow(iss - 0.02, 15)
      : 6.42 * iss;
  if (impact <= 0) return 0;
  final exploitability = 8.22 * av * ac * pr * ui;
  final raw = scopeChanged
      ? 1.08 * (impact + exploitability)
      : impact + exploitability;

  return _roundUp(min(raw, 10));
}

/// CVSS v3.1 Roundup: the smallest one-decimal number >= [value], computed
/// on integers to dodge floating point noise.
double _roundUp(double value) {
  final scaled = (value * 100000).round();
  if (scaled % 10000 == 0) return scaled / 100000;

  return ((scaled / 10000).floor() + 1) / 10;
}

/// The metric map of a well-formed v3 vector, or null.
Map<String, String>? _parseMetrics(String vector) {
  final parts = vector.split('/');
  if (parts.length < 9 ||
      (parts.first != 'CVSS:3.1' && parts.first != 'CVSS:3.0')) {
    return null;
  }
  final metrics = <String, String>{};
  for (final part in parts.skip(1)) {
    final kv = part.split(':');
    if (kv.length != 2) return null;
    metrics[kv.first] = kv.last;
  }

  return metrics;
}
