import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/phrase_config.dart';

import 'support/temp_workspace.dart';

const List<({String description, String yaml})> _rejectedCases = [
  (
    description: 'an exception missing its reason',
    yaml: '''
exceptions:
  - phrase: x
    sentence: y
    date: "2026-01-01"
''',
  ),
  (
    description: 'an exception with a malformed date',
    yaml: '''
exceptions:
  - phrase: x
    sentence: y
    reason: z
    date: "1 Jan 2026"
''',
  ),
  (description: 'malformed YAML', yaml: 'phrases: [unclosed'),
  (description: "a 'phrases' key that is not a list", yaml: 'phrases: nope\n'),
  (description: 'a non-string phrase', yaml: 'phrases:\n  - {a: b}\n'),
];

void main() {
  // Fixture-per-test pattern, as in licence_exception_test.dart.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('phrase_config_'));
  tearDown(() => workspace.dispose());

  test('a missing file forbids nothing', () {
    final config = loadPhraseConfig(p.join(workspace.root.path, 'nope.yaml'));

    expect(config.phrases, isEmpty);
    expect(config.exceptions, isEmpty);
  });

  test('the shipped template list is empty', () {
    final config = loadPhraseConfig(
      p.join(Directory.current.path, '../../../tool/phrase-check.yaml'),
    );

    expect(config.phrases, isEmpty);
    expect(config.sources, isEmpty);
    expect(config.exceptions, isEmpty);
  });

  test('parses phrases, sources and a keyed exception', () {
    final path = workspace.writeFile('p.yaml', '''
phrases: [barrierefrei, rechtssicher]
sources: [extra]
exceptions:
  - phrase: barrierefrei
    sentence: "Nicht barrierefrei zertifiziert."
    reason: negation
    date: "2026-01-31"
''');

    final config = loadPhraseConfig(path);

    expect(config.phrases, ['barrierefrei', 'rechtssicher']);
    expect(config.sources, ['extra']);
    expect(config.exceptions.single.date, '2026-01-31');
    expect(
      config.exceptions.single.covers(
        'Barrierefrei',
        'Nicht  barrierefrei zertifiziert.',
      ),
      isTrue,
    );
    expect(
      config.exceptions.single.covers('barrierefrei', 'Andere Zeile.'),
      isFalse,
    );
  });

  for (final rejected in _rejectedCases) {
    test('rejects ${rejected.description}', () {
      final path = workspace.writeFile('bad.yaml', rejected.yaml);

      expect(() => loadPhraseConfig(path), throwsA(isA<CommandFailure>()));
    });
  }
}
