import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/licence_exception.dart';

import 'support/temp_workspace.dart';

/// One case where `loadLicenceExceptions` should throw [CommandFailure]:
/// a `description` of what's wrong with the `yaml` text.
typedef _RejectedCase = ({String description, String yaml});

const List<_RejectedCase> _rejectedCases = <_RejectedCase>[
  (
    description: 'missing a required field',
    yaml: '''
exceptions:
  - package: some_pkg
    licence: MPL-2.0
''',
  ),
  (description: 'malformed YAML', yaml: 'exceptions: [this is not a list'),
  (
    description: "an 'exceptions' key that isn't a list",
    yaml: 'exceptions: not-a-list\n',
  ),
];

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('licence_exception_'));
  tearDown(() => workspace.dispose());

  test('a missing file yields no exceptions, not a failure', () {
    final path = p.join(workspace.root.path, 'does-not-exist.yaml');

    expect(loadLicenceExceptions(path), isEmpty);
  });

  test('an empty exceptions list parses cleanly', () {
    final path = workspace.writeFile(
      'licence-exceptions.yaml',
      'exceptions: []\n',
    );

    expect(loadLicenceExceptions(path), isEmpty);
  });

  test("a file with no 'exceptions' key (e.g. only a 'verified' list) yields "
      'no exceptions, not a failure', () {
    final path = workspace.writeFile('licence-exceptions.yaml', '''
verified:
  - package: html
    version: "0.15.7"
    licence: MIT
    reason: "Unrelated to exceptions parsing."
''');

    expect(loadLicenceExceptions(path), isEmpty);
  });

  test('parses a full entry, defaulting scope to "all"', () {
    final path = workspace.writeFile('licence-exceptions.yaml', '''
exceptions:
  - package: some_pkg
    licence: MPL-2.0
    reason: "Build-time only, never shipped."
''');

    final exceptions = loadLicenceExceptions(path);

    expect(exceptions, hasLength(1));
    expect(exceptions.single.package, 'some_pkg');
    expect(exceptions.single.licence, 'MPL-2.0');
    expect(exceptions.single.scope, 'all');
  });

  test('an explicit scope is honoured', () {
    final path = workspace.writeFile('licence-exceptions.yaml', '''
exceptions:
  - package: some_pkg
    licence: MPL-2.0
    reason: "Dev tooling only."
    scope: dev
''');

    expect(loadLicenceExceptions(path).single.scope, 'dev');
  });

  test('covers() matches only the exact (package, licence) pair', () {
    const exception = LicenceException(
      package: 'some_pkg',
      licence: 'MPL-2.0',
      reason: 'because',
    );

    expect(exception.covers('some_pkg', 'MPL-2.0'), isTrue);
    expect(exception.covers('some_pkg', 'GPL-3.0-only'), isFalse);
    expect(exception.covers('other_pkg', 'MPL-2.0'), isFalse);
  });

  for (final rejected in _rejectedCases) {
    test('rejects a file with ${rejected.description}', () {
      final path = workspace.writeFile(
        'licence-exceptions.yaml',
        rejected.yaml,
      );

      expect(() => loadLicenceExceptions(path), throwsA(isA<CommandFailure>()));
    });
  }
}
