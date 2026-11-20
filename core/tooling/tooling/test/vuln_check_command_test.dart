// Fixture data (HTTP statuses, JSON shapes of the OSV API) and fake-client
// callbacks; naming each status or silencing each empty no-op would only add
// noise to the tests.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/no_empty_block

import 'package:test/test.dart';
import 'package:tooling/src/vuln_check_command.dart';

import 'support/fake_osv.dart';
import 'support/temp_workspace.dart';

const String _critical = 'GHSA-aaaa-bbbb-cccc';
const String _moderate = 'GHSA-dddd-eeee-ffff';

Map<String, dynamic> _record(String id, Map<String, dynamic> extra) => {
  'id': id,
  'summary': 'Summary of $id',
  ...extra,
};

void main() {
  // Per-test fixtures, same pattern as licence_check_command_test.dart.
  // Assigned in setUp, disposed in tearDown (fixture pattern).
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;
  // Assigned in setUp, disposed in tearDown (fixture pattern).
  // ignore: solid_lints/avoid_late_keyword
  late List<String> out;
  // Assigned in setUp, disposed in tearDown (fixture pattern).
  // ignore: solid_lints/avoid_late_keyword
  late List<String> err;

  setUp(() {
    workspace = TempWorkspace.create('vuln_cmd_');
    out = <String>[];
    err = <String>[];
    // The deliberate break: a lockfile pinning a version with a known advisory.
    workspace.writeFile('pubspec.lock', '''
packages:
  vulnerable_pkg:
    dependency: "direct main"
    description:
      name: vulnerable_pkg
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  fine_pkg:
    dependency: "direct main"
    description:
      name: fine_pkg
      url: "https://pub.dev"
    source: hosted
    version: "2.0.0"
  local_pkg:
    dependency: "direct main"
    description:
      path: "."
      relative: true
    source: path
    version: "0.0.1"
''');
  });
  tearDown(() => workspace.dispose());

  FakeOsv osvWith(Map<String, dynamic> severityFields) => FakeOsv(
    advisoriesByPackage: {
      'vulnerable_pkg@1.0.0': [_critical],
    },
    records: {_critical: _record(_critical, severityFields)},
  );

  Future<int> run(FakeOsv osv, {DateTime? today}) => VulnCheckCommand(
    repoRoot: workspace.root.path,
    client: osv.client(),
    lockfilePaths: const ['pubspec.lock'],
    today: () => today ?? DateTime.utc(2026, 10),
  ).run(out: out.add, err: err.add);

  void writeException({String expires = '2027-01-01'}) =>
      workspace.writeFile('tool/vuln-exceptions.yaml', '''
exceptions:
  - package: vulnerable_pkg
    advisory: $_critical
    reason: "Not reachable: only used in a dev tool."
    date: "2026-09-30"
    expires: "$expires"
''');

  test('rejects a pinned vulnerable version (critical label)', () async {
    final osv = osvWith({
      'database_specific': {'severity': 'CRITICAL'},
    });

    expect(await run(osv), 1);
    expect(out.join('\n'), contains('vulnerable_pkg 1.0.0: $_critical'));
    expect(out.join('\n'), contains('Blocking advisories'));
    expect(err.join(), contains('1 critical/high'));
    // Workspace members and only hosted versions are queried.
    expect(osv.requests, ['POST /v1/querybatch', 'GET /v1/vulns/$_critical']);
  });

  test('rejects a high CVSS v3 vector without a label', () async {
    final osv = osvWith({
      'severity': [
        {
          'type': 'CVSS_V3',
          'score': 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H',
        },
      ],
    });

    expect(await run(osv), 1);
    expect(out.join('\n'), contains('CRITICAL'));
  });

  test('an advisory without a parseable severity counts as high', () async {
    expect(await run(osvWith({})), 1);
    expect(out.join('\n'), contains('unrated, assumed'));
  });

  test('a moderate advisory is listed but does not fail', () async {
    final osv = FakeOsv(
      advisoriesByPackage: {
        'vulnerable_pkg@1.0.0': [_moderate],
      },
      records: {
        _moderate: _record(_moderate, {
          'database_specific': {'severity': 'MODERATE'},
        }),
      },
    );

    expect(await run(osv), 0);
    expect(out.join('\n'), contains('Below threshold'));
    expect(err, isEmpty);
  });

  test('a withdrawn advisory is ignored', () async {
    final osv = osvWith({
      'withdrawn': '2026-02-01T00:00:00Z',
      'database_specific': {'severity': 'CRITICAL'},
    });

    expect(await run(osv), 0);
  });

  test('a clean tree passes', () async {
    expect(await run(FakeOsv()), 0);
    expect(out.first, contains('2 package version(s) checked'));
    expect(out.join('\n'), contains('Active exceptions: none.'));
  });

  test('an active exception passes and is printed', () async {
    writeException();
    final osv = osvWith({
      'database_specific': {'severity': 'CRITICAL'},
    });

    expect(await run(osv), 0);
    final text = out.join('\n');
    expect(text, contains('Active exceptions (1):'));
    expect(text, contains('Not reachable'));
    expect(text, contains('Excepted advisories'));
  });

  test('an exception matches an alias of the advisory', () async {
    workspace.writeFile('tool/vuln-exceptions.yaml', '''
exceptions:
  - package: vulnerable_pkg
    advisory: CVE-2026-0001
    reason: "r"
    date: "2026-09-30"
    expires: "2027-01-01"
''');
    final osv = osvWith({
      'aliases': ['CVE-2026-0001'],
      'database_specific': {'severity': 'HIGH'},
    });

    expect(await run(osv), 0);
  });

  test('an exception for another package does not cover it', () async {
    workspace.writeFile('tool/vuln-exceptions.yaml', '''
exceptions:
  - package: other_pkg
    advisory: $_critical
    reason: "r"
    date: "2026-09-30"
    expires: "2027-01-01"
''');
    final osv = osvWith({
      'database_specific': {'severity': 'HIGH'},
    });

    expect(await run(osv), 1);
  });

  test('an expired exception fails the check, even with no advisory', () async {
    writeException(expires: '2026-09-30');

    expect(await run(FakeOsv()), 1);
    expect(out.join('\n'), contains('EXPIRED exceptions (1)'));
    expect(err.join(), contains('1 expired'));
  });

  test('an exception is still valid on its expiry day', () async {
    writeException(expires: '2026-10-01');

    expect(await run(FakeOsv()), 0);
  });
}
