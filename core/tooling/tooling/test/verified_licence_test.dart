import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/verified_licence.dart';

import 'support/temp_workspace.dart';

/// One case where `loadVerifiedLicences` should throw [CommandFailure]: a
/// `description` of what's wrong with the `yaml` text.
typedef _RejectedCase = ({String description, String yaml});

const List<_RejectedCase> _rejectedCases = <_RejectedCase>[
  (
    description: 'missing a required field',
    yaml: '''
verified:
  - package: html
    version: "0.15.7"
''',
  ),
  (description: 'malformed YAML', yaml: 'verified: [this is not a list'),
  (
    description: "a 'verified' key that isn't a list",
    yaml: 'verified: not-a-list\n',
  ),
];

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('verified_licence_'));
  tearDown(() => workspace.dispose());

  test('a missing file yields no entries, not a failure', () {
    final path = p.join(workspace.root.path, 'does-not-exist.yaml');

    expect(loadVerifiedLicences(path), isEmpty);
  });

  test('a file with no verified: key yields no entries', () {
    final path = workspace.writeFile(
      'licence-exceptions.yaml',
      'exceptions: []\n',
    );

    expect(loadVerifiedLicences(path), isEmpty);
  });

  test('an empty verified list parses cleanly', () {
    final path = workspace.writeFile(
      'licence-exceptions.yaml',
      'verified: []\n',
    );

    expect(loadVerifiedLicences(path), isEmpty);
  });

  test('parses a full entry', () {
    final path = workspace.writeFile('licence-exceptions.yaml', '''
verified:
  - package: html
    version: "0.15.7"
    licence: MIT
    reason: "pub.dev reports license:unknown; LICENSE is the verbatim MIT text."
''');

    final verified = loadVerifiedLicences(path);

    expect(verified, hasLength(1));
    expect(verified.single.package, 'html');
    expect(verified.single.version, '0.15.7');
    expect(verified.single.licence, 'MIT');
  });

  test('covers() matches only the exact (package, version) pair', () {
    const entry = VerifiedLicence(
      package: 'html',
      version: '0.15.7',
      licence: 'MIT',
      reason: 'because',
    );

    expect(entry.covers('html', '0.15.7'), isTrue);
    expect(entry.covers('html', '0.15.8'), isFalse);
    expect(entry.covers('other_pkg', '0.15.7'), isFalse);
  });

  for (final rejected in _rejectedCases) {
    test('rejects a file with ${rejected.description}', () {
      final path = workspace.writeFile(
        'licence-exceptions.yaml',
        rejected.yaml,
      );

      expect(() => loadVerifiedLicences(path), throwsA(isA<CommandFailure>()));
    });
  }
}
