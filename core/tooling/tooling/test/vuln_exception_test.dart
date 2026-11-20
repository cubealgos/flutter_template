// Fixture data (HTTP statuses, JSON shapes of the OSV API) and fake-client
// callbacks; naming each status or silencing each empty no-op would only add
// noise to the tests.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/no_empty_block

import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/vuln_exception.dart';

import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp, disposed in tearDown (fixture pattern).
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;
  setUp(() => workspace = TempWorkspace.create('vuln_exc_'));
  tearDown(() => workspace.dispose());

  String write(String body) => workspace.writeFile('e.yaml', body);

  test('a missing file or empty list means no exceptions', () {
    expect(loadVulnExceptions('${workspace.root.path}/nope.yaml'), isEmpty);
    expect(loadVulnExceptions(write('exceptions: []\n')), isEmpty);
  });

  test('parses an entry, including unquoted dates', () {
    final list = loadVulnExceptions(
      write('''
exceptions:
  - package: p
    advisory: GHSA-1
    reason: because
    date: 2026-09-30
    expires: 2026-12-31
'''),
    );
    expect(list.single.package, 'p');
    expect(list.single.expires, DateTime.utc(2026, 12, 31));
    expect(list.single.isExpiredOn(DateTime.utc(2026, 12, 31, 23)), isFalse);
    expect(list.single.isExpiredOn(DateTime.utc(2027)), isTrue);
  });

  const head = 'package: p\n    advisory: a\n    reason: r\n';
  for (final (name, body) in [
    ('no expiry', '$head    date: "2026-01-01"'),
    ('bad date', '$head    date: "soon"\n    expires: "2026-01-01"'),
    (
      'expires before granted',
      '$head    date: "2026-02-01"\n    expires: "2026-01-01"',
    ),
    (
      'no reason',
      'package: p\n    advisory: a\n    date: "2026-01-01"\n'
          '    expires: "2026-02-01"',
    ),
  ]) {
    test('rejects an entry with $name', () {
      expect(
        () => loadVulnExceptions(write('exceptions:\n  - $body\n')),
        throwsA(isA<CommandFailure>()),
      );
    });
  }
}
