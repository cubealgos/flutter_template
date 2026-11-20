import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';
import 'package:tooling/src/sbom_command.dart';

import 'support/fake_dart_process_runner.dart';
import 'support/fake_dependency_graph.dart';
import 'support/fake_pub_dev_licence_client.dart';
import 'support/temp_workspace.dart';

/// A syntactically valid (64 hex-looking chars), obviously-fake SHA-256
/// used everywhere a test needs *some* lockfile hash string, never a real
/// one.
const String _fakeSha256 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

/// A minimal stand-in for the real root `LICENSE`'s own opening lines —
/// just enough for `root_licence.dart`'s `detectRootLicenceSpdxId` to
/// recognise it as Apache-2.0, without vendoring the whole 202-line text
/// into a test fixture.
const String _fakeApacheLicenceText = '''
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/
''';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;
  // Collects SbomCommand's own progress messages; reset in setUp.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> out;
  // Collects SbomCommand's own warning messages; reset in setUp.
  // ignore: solid_lints/avoid_late_keyword
  late List<String> err;

  setUp(() {
    workspace = TempWorkspace.create('sbom_command_');
    out = <String>[];
    err = <String>[];
    _writeFakeFlutterSdk(workspace);
    workspace
      ..writeFile('pubspec.yaml', 'name: example_app_workspace\n')
      ..writeFile('LICENSE', _fakeApacheLicenceText)
      ..writeFile('pubspec.lock', '''
packages:
  http:
    dependency: transitive
    description:
      name: http
      sha256: "$_fakeSha256"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.3"
  meta:
    dependency: transitive
    description:
      name: meta
      url: "https://pub.dev"
    source: hosted
    version: "1.16.0"
''');
  });
  tearDown(() => workspace.dispose());

  PubDevLicenceClient fakeClient(Map<String, List<String>> tagsByName) =>
      fakePubDevLicenceClient(
        cacheDir: p.join(workspace.root.path, '.dart_tool', 'licence_check'),
        tagsByName: tagsByName,
      );

  SbomCommand buildCommand(PubDevLicenceClient client) => SbomCommand(
    repoRoot: workspace.root.path,
    runner: FakeDartProcessRunner(
      _fakeDartExecutable(workspace),
      fakePubDepsJson,
    ),
    licenceClient: client,
    dartExecutable: _fakeDartExecutable(workspace),
    out: out.add,
    err: err.add,
  );

  test('writes a valid CycloneDX document for the default app', () async {
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
        'meta': ['bsd-3-clause'],
      }),
    );

    final exitCode = await command.run();

    expect(exitCode, 0);
    final outputFile = workspace.file(
      p.join('build', 'release', 'app', 'sbom.cdx.json'),
    );
    expect(outputFile.existsSync(), isTrue);
    final doc = jsonDecode(outputFile.readAsStringSync()) as Map;
    expect(doc['bomFormat'], 'CycloneDX');
    expect(doc['specVersion'], '1.6');
    final componentNames = (doc['components'] as List)
        .map((c) => (c as Map)['name'])
        .toSet();
    expect(componentNames, {'http', 'mvc', 'flutter', 'meta', 'sky_engine'});
    expect(out.join('\n'), contains('5 component(s)'));
  });

  test('a hosted component carries its lockfile sha256 hash', () async {
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
        'meta': ['bsd-3-clause'],
      }),
    );
    await command.run();

    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;
    final http = (doc['components'] as List).firstWhere(
      (c) => (c as Map)['name'] == 'http',
    ) as Map;

    expect(http['hashes'], [
      {'alg': 'SHA-256', 'content': _fakeSha256},
    ]);
  });

  test('falls back to a verified: override when pub.dev has no tag', () async {
    workspace.writeFile(p.join('tool', 'licence-exceptions.yaml'), '''
exceptions: []
verified:
  - package: meta
    version: 1.16.0
    licence: BSD-3-Clause
    reason: "test fixture — no real pub.dev call happens."
''');
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
      }),
    );

    await command.run();

    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;
    final meta = (doc['components'] as List).firstWhere(
      (c) => (c as Map)['name'] == 'meta',
    ) as Map;

    expect(meta['licenses'], [
      {
        'license': {'id': 'BSD-3-Clause'},
      },
    ]);
  });

  test("a first-party component gets a generic purl and the root LICENSE's "
      'SPDX id', () async {
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
        'meta': ['mit'],
      }),
    );
    await command.run();

    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;
    final mvc = (doc['components'] as List).firstWhere(
      (c) => (c as Map)['name'] == 'mvc',
    ) as Map;

    expect(mvc['purl'], 'pkg:generic/example_app/mvc@0.0.0');
    expect(mvc['licenses'], [
      {
        'license': {'id': 'Apache-2.0'},
      },
    ]);
  });

  test("a renamed clone's workspace pubspec name drives the purl namespace, "
      'not a fixed one', () async {
    workspace.writeFile('pubspec.yaml', 'name: acme_notes_workspace\n');
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
        'meta': ['mit'],
      }),
    );
    await command.run();

    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;
    final mvc = (doc['components'] as List).firstWhere(
      (c) => (c as Map)['name'] == 'mvc',
    ) as Map;
    // metadata.component is always present — buildCycloneDxBom always
    // writes it (see cyclonedx_document.dart).
    // ignore: solid_lints/avoid_non_null_assertion
    final metadata = doc['metadata']! as Map;
    // Same guarantee as metadata's own assertion above.
    // ignore: solid_lints/avoid_non_null_assertion
    final component = metadata['component']! as Map;

    expect(mvc['purl'], 'pkg:generic/acme_notes/mvc@0.0.0');
    expect(component['purl'], 'pkg:generic/acme_notes/app@1.0.0+1');
  });

  test(
    "warns and omits the licence when the root LICENSE can't be identified",
    () async {
      workspace.writeFile('LICENSE', 'Some bespoke licence text.\n');
      final command = buildCommand(
        fakeClient({
          'http': ['mit'],
          'meta': ['mit'],
        }),
      );
      await command.run();

      final doc = jsonDecode(
        workspace
            .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
            .readAsStringSync(),
      ) as Map;
      final mvc = (doc['components'] as List).firstWhere(
        (c) => (c as Map)['name'] == 'mvc',
      ) as Map;

      expect(mvc.containsKey('licenses'), isFalse);
      expect(err.join('\n'), contains('could not identify an SPDX id'));
    },
  );

  test('an SDK component gets the Flutter SDK version and licence', () async {
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
        'meta': ['mit'],
      }),
    );
    await command.run();

    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;
    final flutter = (doc['components'] as List).firstWhere(
      (c) => (c as Map)['name'] == 'flutter',
    ) as Map;

    expect(flutter['type'], 'framework');
    expect(flutter['version'], '3.47.5');
    expect(flutter['licenses'], [
      {
        'license': {'id': 'BSD-3-Clause'},
      },
    ]);
  });

  test('an explicit timestamp is used verbatim', () async {
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
        'meta': ['mit'],
      }),
    );

    await command.run((
      appPackageName: 'app',
      timestamp: DateTime.utc(2026, 1, 2, 3),
      serialNumber: null,
      outputPath: null,
    ));

    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'app', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;

    expect((doc['metadata'] as Map)['timestamp'], '2026-01-02T03:00:00.000Z');
  });

  test('a smaller app produces a smaller, valid SBOM', () async {
    final command = buildCommand(
      fakeClient({
        'http': ['mit'],
      }),
    );

    final exitCode = await command.run((
      appPackageName: 'website',
      timestamp: null,
      serialNumber: null,
      outputPath: null,
    ));

    expect(exitCode, 0);
    final doc = jsonDecode(
      workspace
          .file(p.join('build', 'release', 'website', 'sbom.cdx.json'))
          .readAsStringSync(),
    ) as Map;
    expect((doc['components'] as List).length, 1);
  });

  test('exits non-zero for an unknown app package name', () async {
    final command = buildCommand(fakeClient({}));

    final exitCode = await command.run((
      appPackageName: 'no_such_app',
      timestamp: null,
      serialNumber: null,
      outputPath: null,
    ));

    expect(exitCode, isNot(0));
  });
}

/// Writes a fake Flutter SDK under `<workspace>/fake_sdk/`, just enough
/// for `flutter_sdk_locator.dart` to resolve a version from: the
/// `bin/cache/dart-sdk/bin` suffix `resolveFlutterSdkRoot` requires, plus
/// `bin/cache/flutter.version.json`.
void _writeFakeFlutterSdk(TempWorkspace workspace) {
  workspace.writeFile(
    p.join('fake_sdk', 'bin', 'cache', 'flutter.version.json'),
    jsonEncode({'frameworkVersion': '3.47.5', 'channel': 'stable'}),
  );
}

String _fakeDartExecutable(TempWorkspace workspace) => p.join(
  workspace.root.path,
  'fake_sdk',
  'bin',
  'cache',
  'dart-sdk',
  'bin',
  'dart',
);
