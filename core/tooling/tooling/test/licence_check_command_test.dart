import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/licence_check_command.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';

import 'support/fake_pub_dev_licence_client.dart';
import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;
  // Reset per test in setUp, same fixture pattern as workspace above.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> out;
  // Reset per test in setUp, same fixture pattern as workspace above.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> err;

  setUp(() {
    workspace = TempWorkspace.create('licence_cmd_');
    out = <String>[];
    err = <String>[];
  });
  tearDown(() => workspace.dispose());

  String writeLockfile(String relativePath, Map<String, String> hostedByName) {
    final buffer = StringBuffer('packages:\n');
    hostedByName.forEach((name, version) {
      buffer.writeln('''
  $name:
    dependency: "direct main"
    description:
      name: $name
      url: "https://pub.dev"
    source: hosted
    version: "$version"''');
    });

    return workspace.writeFile(relativePath, buffer.toString());
  }

  PubDevLicenceClient clientAnswering(Map<String, List<String>> tagsByName) =>
      fakePubDevLicenceClient(
        cacheDir: p.join(workspace.root.path, '.dart_tool', 'licence_check'),
        tagsByName: tagsByName,
      );

  test(
    'exits 0 and reports allowed when everything is on the allow list',
    () async {
      writeLockfile('pubspec.lock', {'good_pkg': '1.0.0'});
      final command = LicenceCheckCommand(
        repoRoot: workspace.root.path,
        client: clientAnswering({
          'good_pkg': ['mit'],
        }),
        lockfilePaths: const ['pubspec.lock'],
      );

      final exitCode = await command.run(out: out.add, err: err.add);

      expect(exitCode, 0);
      expect(out.join('\n'), contains('1 allowed'));
      expect(out.join('\n'), contains('Active exceptions: none.'));
    },
  );

  test('exits 1 and lists a denied package by name and licence', () async {
    writeLockfile('pubspec.lock', {'bad_pkg': '2.0.0'});
    final command = LicenceCheckCommand(
      repoRoot: workspace.root.path,
      client: clientAnswering({
        'bad_pkg': ['gpl-3.0-only'],
      }),
      lockfilePaths: const ['pubspec.lock'],
    );

    final exitCode = await command.run(out: out.add, err: err.add);

    expect(exitCode, 1);
    expect(out.join('\n'), contains('bad_pkg'));
    expect(out.join('\n'), contains('GPL-3.0-only'));
    expect(err.join('\n'), contains('bad_pkg'));
  });

  test('MPL-2.0 is denied without a matching exception', () async {
    writeLockfile('pubspec.lock', {'mpl_pkg': '1.0.0'});
    final command = LicenceCheckCommand(
      repoRoot: workspace.root.path,
      client: clientAnswering({
        'mpl_pkg': ['mpl-2.0'],
      }),
      lockfilePaths: const ['pubspec.lock'],
    );

    expect(await command.run(out: out.add, err: err.add), 1);
  });

  test(
    'MPL-2.0 is allowed, and reported, with a matching keyed exception',
    () async {
      writeLockfile('pubspec.lock', {'mpl_pkg': '1.0.0'});
      workspace.writeFile('tool/licence-exceptions.yaml', '''
exceptions:
  - package: mpl_pkg
    licence: MPL-2.0
    reason: "Build-time only, never shipped."
''');
      final command = LicenceCheckCommand(
        repoRoot: workspace.root.path,
        client: clientAnswering({
          'mpl_pkg': ['mpl-2.0'],
        }),
        lockfilePaths: const ['pubspec.lock'],
      );

      final exitCode = await command.run(out: out.add, err: err.add);

      expect(exitCode, 0);
      expect(out.join('\n'), contains('1 exempted'));
      expect(out.join('\n'), contains('mpl_pkg'));
      expect(out.join('\n'), contains('Build-time only, never shipped.'));
    },
  );

  test(
    'an exception keyed to a different licence does not cover a relicense',
    () async {
      writeLockfile('pubspec.lock', {'mpl_pkg': '1.0.0'});
      workspace.writeFile('tool/licence-exceptions.yaml', '''
exceptions:
  - package: mpl_pkg
    licence: MIT
    reason: "Recorded for a licence this package no longer carries."
''');
      final command = LicenceCheckCommand(
        repoRoot: workspace.root.path,
        client: clientAnswering({
          'mpl_pkg': ['mpl-2.0'],
        }),
        lockfilePaths: const ['pubspec.lock'],
      );

      expect(await command.run(out: out.add, err: err.add), 1);
    },
  );

  test('a package with no licence tag is denied, not skipped', () async {
    writeLockfile('pubspec.lock', {'mystery_pkg': '1.0.0'});
    final command = LicenceCheckCommand(
      repoRoot: workspace.root.path,
      client: clientAnswering({
        'mystery_pkg': ['unknown'],
      }),
      lockfilePaths: const ['pubspec.lock'],
    );

    final exitCode = await command.run(out: out.add, err: err.add);

    expect(exitCode, 1);
    expect(out.join('\n'), contains('mystery_pkg'));
  });

  test(
    'a package appearing in two lockfiles is fetched once, versions merged',
    () async {
      writeLockfile('pubspec.lock', {'shared_pkg': '1.0.0'});
      writeLockfile('core/architecture/mvc_lints/pubspec.lock', {
        'shared_pkg': '1.0.0',
      });
      var fetchCount = 0;
      final client = PubDevLicenceClient(
        cacheDir: p.join(workspace.root.path, '.dart_tool', 'licence_check'),
        httpClient: MockClient((_) async {
          fetchCount++;

          return http.Response(
            jsonEncode({
              'tags': ['license:mit'],
            }),
            fakePubDevStatusOk,
          );
        }),
      );
      final command = LicenceCheckCommand(
        repoRoot: workspace.root.path,
        client: client,
      );

      expect(await command.run(out: out.add, err: err.add), 0);
      expect(fetchCount, 1);
    },
  );

  test(
    'a missing lockfile in the default set is skipped, not a failure',
    () async {
      writeLockfile('pubspec.lock', {'good_pkg': '1.0.0'});
      // core/architecture/mvc_lints/pubspec.lock is deliberately absent.
      final command = LicenceCheckCommand(
        repoRoot: workspace.root.path,
        client: clientAnswering({
          'good_pkg': ['mit'],
        }),
      );

      expect(await command.run(out: out.add, err: err.add), 0);
    },
  );

  for (final c in _verifiedCases) {
    test(c.description, () async {
      writeLockfile('pubspec.lock', {c.package: c.resolvedVersion});
      workspace.writeFile('tool/licence-exceptions.yaml', c.verifiedYaml);
      final command = LicenceCheckCommand(
        repoRoot: workspace.root.path,
        client: clientAnswering({c.package: c.tags}),
        lockfilePaths: const ['pubspec.lock'],
      );

      final exitCode = await command.run(out: out.add, err: err.add);

      expect(exitCode, c.expectedExitCode);
      for (final fragment in c.expectedOutputContains) {
        expect(out.join('\n'), contains(fragment));
      }
    });
  }
}

/// One [LicenceCheckCommand] run exercising the `verified:` detection-gap
/// path: a single resolved `package`/`resolvedVersion` reporting `tags`,
/// checked against `verifiedYaml`'s `tool/licence-exceptions.yaml`
/// content.
typedef _VerifiedCase = ({
  String description,
  String package,
  String resolvedVersion,
  List<String> tags,
  String verifiedYaml,
  int expectedExitCode,
  List<String> expectedOutputContains,
});

const List<_VerifiedCase> _verifiedCases = <_VerifiedCase>[
  (
    description:
        'a verified entry allows a detection-gap package at the matching '
        'version',
    package: 'html',
    resolvedVersion: '0.15.7',
    tags: ['unknown'],
    verifiedYaml: '''
verified:
  - package: html
    version: "0.15.7"
    licence: MIT
    reason: "pub.dev reports license:unknown; LICENSE is verbatim MIT."
''',
    expectedExitCode: 0,
    expectedOutputContains: ['1 verified', 'html 0.15.7: MIT'],
  ),
  (
    description:
        'a verified entry does not cover a different resolved '
        'version',
    package: 'html',
    resolvedVersion: '0.15.8',
    tags: ['unknown'],
    verifiedYaml: '''
verified:
  - package: html
    version: "0.15.7"
    licence: MIT
    reason: "pub.dev reports license:unknown; LICENSE is verbatim MIT."
''',
    expectedExitCode: 1,
    expectedOutputContains: ['html 0.15.8'],
  ),
  (
    description:
        'a verified entry never overrides a licence pub.dev did '
        'detect',
    package: 'html',
    resolvedVersion: '0.15.7',
    // pub.dev *did* detect something here — a real, denied SPDX id, not
    // an empty/unknown/unrecognised result.
    tags: ['gpl-3.0-only'],
    verifiedYaml: '''
verified:
  - package: html
    version: "0.15.7"
    licence: MIT
    reason: "Would allow it, but pub.dev already detected a real licence."
''',
    expectedExitCode: 1,
    // Detected-but-denied, never routed through the verified path.
    expectedOutputContains: ['GPL-3.0-only', '0 verified'],
  ),
  (
    description:
        "a verified entry whose own licence isn't on the allow "
        'list is still denied',
    package: 'html',
    resolvedVersion: '0.15.7',
    tags: ['unknown'],
    verifiedYaml: '''
verified:
  - package: html
    version: "0.15.7"
    licence: GPL-3.0-only
    reason: "A verified GPL is still denied — this must not pass."
''',
    expectedExitCode: 1,
    expectedOutputContains: ['html 0.15.7'],
  ),
  (
    description:
        'the report lists every verified entry, even one that matched '
        'nothing',
    package: 'good_pkg',
    resolvedVersion: '1.0.0',
    tags: ['mit'],
    verifiedYaml: '''
verified:
  - package: some_other_pkg
    version: "9.9.9"
    licence: MIT
    reason: "Unrelated to this run's dependency graph."
''',
    expectedExitCode: 0,
    expectedOutputContains: [
      'Verified detection-gap overrides (1):',
      'some_other_pkg 9.9.9',
    ],
  ),
];
