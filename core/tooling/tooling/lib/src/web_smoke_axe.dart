import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';

/// The pinned version of the vendored axe-core
/// (`core/tooling/tooling/third_party/axe-core/axe.min.js`).
const String axeVersion = '4.13.0';

/// SHA-256 of the vendored `axe.min.js`. [loadAxeSource] refuses a file
/// that doesn't match, so the pinned version can't be swapped silently.
const String axeSha256 =
    'c24f097bd2f451d4f933e8bc7d8d539f8672a2ebcb5cc9f9f3eec8ca9470a0c1';

/// The axe impacts that fail `web_smoke`.
const Set<String> axeFailingImpacts = {'serious', 'critical'};

/// How many offending nodes [axeProblems] names per violation.
const int _maxNodesShown = 3;

/// Reads the vendored axe-core source under [repoRoot] and checks it
/// against [axeSha256] (or [expectedSha256], for tests).
String loadAxeSource(String repoRoot, {String expectedSha256 = axeSha256}) {
  final file = File(
    p.join(
      repoRoot,
      'core',
      'tooling',
      'tooling',
      'third_party',
      'axe-core',
      'axe.min.js',
    ),
  );
  if (!file.existsSync()) {
    throw CommandFailure('${file.path} not found (vendored axe-core).');
  }
  final bytes = file.readAsBytesSync();
  final actual = sha256.convert(bytes).toString();
  if (actual != expectedSha256) {
    throw CommandFailure(
      '${file.path} has sha256 $actual, expected $expectedSha256 — the '
      'vendored axe-core no longer matches its pin.',
    );
  }

  return utf8.decode(bytes);
}

/// The expression that runs axe over the whole document and resolves to a
/// JSON string of its `violations`, reduced to the fields [axeProblems]
/// reads. Evaluate with `awaitPromise: true`.
const String axeRunExpression = '''
axe.run(document).then((results) => JSON.stringify(
  results.violations.map((v) => ({
    id: v.id,
    impact: v.impact,
    help: v.help,
    nodes: v.nodes.map((n) => n.target.join(' ')),
  }))
))
''';

/// Turns the JSON [axeRunExpression] produced into one problem line per
/// violation whose impact is in [axeFailingImpacts].
List<String> axeProblems(String violationsJson) {
  final violations = (jsonDecode(violationsJson) as List)
      .cast<Map<String, dynamic>>();

  return [
    for (final v in violations)
      if (axeFailingImpacts.contains(v['impact'])) _describe(v),
  ];
}

String _describe(Map<String, dynamic> v) {
  final nodes = (v['nodes'] as List).take(_maxNodesShown).join('; ');

  return 'axe ${v['impact']} "${v['id']}": ${v['help']} — $nodes';
}
