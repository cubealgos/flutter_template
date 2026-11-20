import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/phrase_check_command.dart';

import 'support/temp_workspace.dart';

const String _fixtureList = 'test/fixtures/phrase_check/phrase-check.yaml';

void main() {
  // Fixture-per-test pattern, as in licence_check_command_test.dart.
  // Per-test fixture state, as in licence_check_command_test.dart.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;
  // Per-test fixture state, as in licence_check_command_test.dart.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> out;
  // Per-test fixture state, as in licence_check_command_test.dart.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> err;

  setUp(() {
    workspace = TempWorkspace.create('phrase_cmd_');
    out = <String>[];
    err = <String>[];
  });
  tearDown(() => workspace.dispose());

  int run() =>
      PhraseCheckCommand(repoRoot: workspace.root.path)
          .run(out: out.add, err: err.add);

  void useSampleList() {
    workspace
      ..writeFile(
        'tool/phrase-check.yaml',
        File(_fixtureList).readAsStringSync(),
      )
      // The sample list's `sources: [extra]` must exist.
      ..writeFile('extra/.keep', '');
  }

  test('the empty template list passes over any copy', () {
    workspace
      ..writeFile(
        'apps/app/lib/i18n/de.i18n.json',
        '{"a": "Barrierefrei und rechtssicher."}',
      )
      ..writeFile('tool/phrase-check.yaml', 'phrases: []\n');

    expect(run(), 0);
    expect(out.join('\n'), contains('0 forbidden phrase(s)'));
    expect(out.join('\n'), contains('Active exceptions: none.'));
  });

  test('deliberate break: a forbidden phrase in app i18n JSON fails', () {
    useSampleList();
    workspace.writeFile(
      'apps/app/lib/i18n/de.i18n.json',
      '{"home": {"claim": "Unsere App ist barrierefrei. Und schön."}}',
    );

    expect(run(), 1);
    expect(
      out.join('\n'),
      contains(
        'apps/app/lib/i18n/de.i18n.json (home.claim): "barrierefrei" in '
        '"Unsere App ist barrierefrei."',
      ),
    );
    expect(err.join('\n'), contains('1 forbidden phrase occurrence'));
  });

  test('catches umlaut and ß forms in uppercase', () {
    useSampleList();
    workspace.writeFile(
      'apps/app/lib/i18n/en.i18n.json',
      '{"a": "ALLES IST KI-GESTÜTZT", "b": "BFSG-KONFORM"}',
    );

    expect(run(), 1);
    expect(out.join('\n'), contains('"KI-gestützt"'));
    expect(out.join('\n'), contains('"BFSG-konform"'));
  });

  test('does not flag Barrierefreiheit when only barrierefrei is listed', () {
    useSampleList();
    workspace.writeFile(
      'apps/app/lib/i18n/de.i18n.json',
      '{"a": "Barrierefreiheit ist uns wichtig."}',
    );

    expect(run(), 0);
  });

  test('a keyed exception passes and is printed on every run', () {
    useSampleList();
    workspace.writeFile(
      'apps/app/lib/i18n/de.i18n.json',
      '{"a": "Diese Seite ist nicht barrierefrei zertifiziert."}',
    );

    expect(run(), 0);
    expect(out.join('\n'), contains('Active exceptions (1):'));
    expect(
      out.join('\n'),
      contains(
        '"barrierefrei" in "Diese Seite ist nicht barrierefrei '
        'zertifiziert." (2026-01-31): Negates the claim.',
      ),
    );
  });

  test('an exception does not cover the phrase in another sentence', () {
    useSampleList();
    workspace.writeFile(
      'apps/app/lib/i18n/de.i18n.json',
      '{"a": "Diese Seite ist nicht barrierefrei zertifiziert.", '
          '"b": "Diese Seite ist barrierefrei zertifiziert."}',
    );

    expect(run(), 1);
    expect(out.join('\n'), contains('(b)'));
    expect(out.join('\n'), isNot(contains('(a): "barrierefrei"')));
  });

  test('scans the website i18n Dart string literals', () {
    useSampleList();
    workspace.writeFile(
      'apps/website/lib/src/i18n/site_strings.dart',
      "const a = 'Wir sind rechtssicher.';\n// rechtssicher in a comment\n",
    );

    expect(run(), 1);
    expect(
      out.join('\n'),
      contains('site_strings.dart (line 1): "rechtssicher"'),
    );
    expect(out.join('\n'), isNot(contains('line 2')));
  });

  test('scans extra sources listed in the phrase file, files and dirs', () {
    useSampleList();
    workspace
      ..writeFile(
        'extra/mail/welcome.txt',
        'Hallo,\nunser Dienst ist rechtssicher.',
      )
      ..writeFile('extra/generated.g.dart', "const a = 'rechtssicher';");

    expect(run(), 1);
    expect(out.join('\n'), contains('extra/mail/welcome.txt (line 2)'));
    expect(out.join('\n'), isNot(contains('generated.g.dart')));
  });

  test('a listed source that does not exist is an error', () {
    workspace.writeFile('tool/phrase-check.yaml', 'sources: [missing]\n');

    expect(run(), 1);
    expect(err.join('\n'), contains("source 'missing' does not exist"));
  });

  test('reports an exception that matches nothing', () {
    useSampleList();

    expect(run(), 0);
    expect(out.join('\n'), contains('[matches nothing now]'));
  });

  test('the sample list lives under the fixtures, not in the template', () {
    expect(
      File(p.join('..', '..', '..', 'tool', 'phrase-check.yaml'))
          .readAsStringSync(),
      contains('phrases: []'),
    );
  });
}
