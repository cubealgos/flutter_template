import 'dart:io';

import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/web_smoke_axe.dart';

const int _failingCount = 2;

String _repoRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync() ||
      !Directory('${dir.path}/core').existsSync()) {
    dir = dir.parent;
  }

  return dir.path;
}

void main() {
  group('axeProblems', () {
    const json = '''
[
  {"id": "button-name", "impact": "critical", "help": "Buttons need names",
   "nodes": ["#a", "#b"]},
  {"id": "region", "impact": "moderate", "help": "Use landmarks", "nodes": ["#c"]},
  {"id": "link-name", "impact": "serious", "help": "Links need names",
   "nodes": ["#d"]}
]
''';

    test('keeps serious and critical, drops the rest', () {
      final problems = axeProblems(json);

      expect(problems, hasLength(_failingCount));
      expect(problems.first, contains('critical "button-name"'));
      expect(problems.first, contains('#a; #b'));
      expect(problems.last, contains('serious "link-name"'));
    });

    test('is empty for no violations', () {
      expect(axeProblems('[]'), isEmpty);
    });
  });

  group('loadAxeSource', () {
    test('accepts the vendored file at its pinned checksum', () {
      expect(loadAxeSource(_repoRoot()), contains('axe'));
    });

    test('refuses a checksum mismatch', () {
      expect(
        () => loadAxeSource(_repoRoot(), expectedSha256: 'deadbeef'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });
}
