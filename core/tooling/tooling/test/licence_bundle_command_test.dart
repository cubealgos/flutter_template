import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/licence_bundle_command.dart';

import 'support/fake_dart_process_runner.dart';
import 'support/fake_dependency_graph.dart';
import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() {
    workspace = TempWorkspace.create('licence_bundle_command_');
    _writeFakePackageGraph(workspace);
  });
  tearDown(() => workspace.dispose());

  LicenceBundleCommand buildCommand() => LicenceBundleCommand(
    repoRoot: workspace.root.path,
    runner: FakeDartProcessRunner(
      _fakeDartExecutable(workspace),
      fakePubDepsJson,
    ),
    dartExecutable: _fakeDartExecutable(workspace),
  );

  test('writes a bundle covering every hosted package plus the SDK', () async {
    final exitCode = await buildCommand().run();

    expect(exitCode, 0);
    final text = workspace
        .file(p.join('build', 'release', 'app', 'THIRD_PARTY_LICENSES'))
        .readAsStringSync();
    expect(text, contains('http 1.2.3'));
    expect(text, contains('MIT text for http'));
    expect(text, contains('meta 1.16.0'));
    expect(text, contains('BSD text for meta'));
    expect(text, contains('Flutter SDK 3.47.5'));
    expect(text, contains('Flutter SDK LICENSE text'));
  });

  test('excludes first-party workspace members from the bundle body', () async {
    await buildCommand().run();

    final text = workspace
        .file(p.join('build', 'release', 'app', 'THIRD_PARTY_LICENSES'))
        .readAsStringSync();

    expect(text, isNot(contains('mvc 0.0.0')));
  });

  test(
    'picks up a font licence declared under a first-party package',
    () async {
      workspace
        ..writeFile(p.join('core', 'design', 'ui', 'pubspec.yaml'), '''
name: ui
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
''')
        ..writeFile(
          p.join('core', 'design', 'ui', 'assets', 'fonts', 'OFL.txt'),
          'SIL Open Font License text',
        );
      _addUiPackageConfigEntry(workspace);
      final graphWithUi = _fakeGraphIncludingUi();

      final command = LicenceBundleCommand(
        repoRoot: workspace.root.path,
        runner: FakeDartProcessRunner(
          _fakeDartExecutable(workspace),
          graphWithUi,
        ),
        dartExecutable: _fakeDartExecutable(workspace),
      );
      await command.run();

      final text = workspace
          .file(p.join('build', 'release', 'app', 'THIRD_PARTY_LICENSES'))
          .readAsStringSync();
      expect(text, contains('SIL Open Font License text'));
    },
  );

  test('fails loudly when a hosted package has no LICENSE file', () async {
    workspace.file(p.join('pub-cache', 'http-1.2.3', 'LICENSE')).deleteSync();

    final result = await buildCommand().run();

    expect(result, isNot(0));
  });

  test('throws for an unknown app package name', () async {
    final exitCode = await buildCommand().run((
      appPackageName: 'no_such_app',
      outputPath: null,
    ));

    expect(exitCode, isNot(0));
  });
}

/// Writes `.dart_tool/package_config.json` (resolving `http`/`meta` to
/// fake pub-cache directories with a `LICENSE` file each, and `app`/`mvc`
/// to their own in-workspace directories), the fake pub-cache LICENSE
/// files themselves, and a fake Flutter SDK
/// (`bin/cache/dart-sdk/bin/dart`'s ancestor, `bin/cache/
/// flutter.version.json`, `LICENSE`) — everything
/// `licence_bundle_command_test.dart` needs before any test runs.
void _writeFakePackageGraph(TempWorkspace workspace) {
  workspace
    ..writeFile(
      p.join('pub-cache', 'http-1.2.3', 'LICENSE'),
      'MIT text for http',
    )
    ..writeFile(
      p.join('pub-cache', 'meta-1.16.0', 'LICENSE'),
      'BSD text for meta',
    )
    ..writeFile(
      p.join('fake_sdk', 'bin', 'cache', 'flutter.version.json'),
      jsonEncode({'frameworkVersion': '3.47.5', 'channel': 'stable'}),
    )
    ..writeFile(p.join('fake_sdk', 'LICENSE'), 'Flutter SDK LICENSE text')
    ..writeFile(
      p.join('.dart_tool', 'package_config.json'),
      jsonEncode({
        'configVersion': 2,
        'packages': [
          _packageConfigEntry('http', p.join('..', 'pub-cache', 'http-1.2.3')),
          _packageConfigEntry('meta', p.join('..', 'pub-cache', 'meta-1.16.0')),
          _packageConfigEntry('app', p.join('..', 'app')),
          _packageConfigEntry('website', p.join('..', 'website')),
          _packageConfigEntry('mvc', p.join('..', 'core', 'mvc')),
        ],
      }),
    );
}

void _addUiPackageConfigEntry(TempWorkspace workspace) {
  final file = workspace.file(p.join('.dart_tool', 'package_config.json'));
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  // decoded is this very test's own _writeFakePackageGraph() output, whose
  // 'packages' key is always present.
  // ignore: solid_lints/avoid_non_null_assertion
  final packages = (decoded['packages']! as List).cast<Map<String, Object?>>()
    ..add(_packageConfigEntry('ui', p.join('..', 'core', 'design', 'ui')));
  file.writeAsStringSync(
    jsonEncode({'configVersion': 2, 'packages': packages}),
  );
}

Map<String, String> _packageConfigEntry(String name, String rootUri) => {
  'name': name,
  'rootUri': rootUri,
  'packageUri': 'lib/',
};

/// `fakePubDepsJson`, plus `ui` (a first-party `rootSource` member `mvc`
/// depends on) — used only by the font-licence test, which needs a real
/// closure member whose own `pubspec.yaml` declares a font.
Map<String, Object?> _fakeGraphIncludingUi() {
  // fakePubDepsJson (support/fake_dependency_graph.dart) always declares
  // a 'packages' key.
  // ignore: solid_lints/avoid_non_null_assertion
  final packages = (fakePubDepsJson['packages']! as List)
      .map((p) => Map<String, Object?>.from(p as Map))
      .toList();
  final mvcIndex = packages.indexWhere((p) => p['name'] == 'mvc');
  packages[mvcIndex] = {
    ...packages[mvcIndex],
    'dependencies': ['flutter', 'ui'],
    'directDependencies': ['flutter', 'ui'],
  };
  packages.add({
    'name': 'ui',
    'version': '0.0.0',
    'kind': 'root',
    'source': 'root',
    'dependencies': <String>[],
    'directDependencies': <String>[],
    'devDependencies': <String>[],
  });

  return {...fakePubDepsJson, 'packages': packages};
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
