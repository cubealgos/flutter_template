import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/rename_command.dart';
import 'package:yaml/yaml.dart';

/// How many argument-list entries a `dart run melos run <script>` fake `fvm`
/// call has, before the script name itself.
const int _melosRunPrefixWidth = 4;

/// A [ProcessRunner] that passes `git` straight through to the real binary
/// (a real disposable local repo is cheap and exactly what the dirty-tree
/// check is testing) but fakes every `fvm` call — `package_rename`, `pub
/// get`, and each `melos run <script>` in `postRenameMelosScripts` — so
/// tests never depend on a real FVM install, a real package_rename run, or
/// a real melos/build_runner toolchain.
///
/// The fake `package_rename` handler simulates the side effects
/// `RenameCommand` itself reads back afterwards (native org/id strings, and
/// `linux/CMakeLists.txt`'s `BINARY_NAME`/`APPLICATION_ID`) from the config
/// file `RenameCommand` wrote — everything else about the real tool is out
/// of scope for this test (see the real end-to-end scratch-clone proof
/// instead).
//
// This file is named for the command under test, not for this private fake
// ProcessRunner (the only class declared here) — matches
// gen_fresh_check_command_test.dart's `_FakeFvmRunner` convention.
// ignore: solid_lints/prefer_match_file_name
class _FakeRenameRunner implements ProcessRunner {
  _FakeRenameRunner({
    this.packageRenameExitCode = 0,
    this.pubGetExitCode = 0,
    this.melosExitCodes = const {},
    this.simulateLinuxCmakeUpdate = true,
  });

  final int packageRenameExitCode;
  final int pubGetExitCode;

  /// Script name → exit code, for scripts that should fail; any script not
  /// listed here succeeds.
  final Map<String, int> melosExitCodes;

  /// Whether the fake `package_rename` call updates `linux/CMakeLists.txt`
  /// — set false to simulate package_rename silently skipping a platform
  /// (its own real, documented behaviour on a caught per-platform error).
  final bool simulateLinuxCmakeUpdate;

  final List<List<String>> fvmCalls = <List<String>>[];

  static const ProcessRunner _real = SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (executable == 'git') {
      return await _real.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
      );
    }
    if (executable != 'fvm') {
      throw StateError('unexpected executable: $executable $arguments');
    }
    fvmCalls.add(arguments);

    return _fvmResult(arguments, workingDirectory);
  }

  ProcessResult _fvmResult(List<String> arguments, String? workingDirectory) {
    if (arguments.contains('package_rename')) {
      if (simulateLinuxCmakeUpdate && workingDirectory != null) {
        _simulatePackageRename(workingDirectory);
      }

      return ProcessResult(0, packageRenameExitCode, '', '');
    }
    if (arguments.join(' ') == 'dart pub get') {
      return ProcessResult(0, pubGetExitCode, '', '');
    }
    final script = _melosScriptOf(arguments);
    if (script != null) {
      return ProcessResult(0, melosExitCodes[script] ?? 0, '', '');
    }
    throw StateError('unexpected fvm call: $arguments');
  }

  String? _melosScriptOf(List<String> arguments) {
    const prefix = ['dart', 'run', 'melos', 'run'];
    if (arguments.length <= _melosRunPrefixWidth) return null;
    for (var i = 0; i < prefix.length; i++) {
      if (arguments[i] != prefix[i]) return null;
    }

    return arguments[_melosRunPrefixWidth];
  }

  void _simulatePackageRename(String appDir) {
    final configFile = File(p.join(appDir, 'package_rename_config.yaml'));
    if (!configFile.existsSync()) return;
    final doc = loadYaml(configFile.readAsStringSync()) as YamlMap;
    final config = doc['package_rename_config'] as YamlMap;
    _swapNativeOrgAndId(appDir, config['android'] as YamlMap);
    if (simulateLinuxCmakeUpdate) _rewriteLinuxCmake(appDir, config);
  }

  void _swapNativeOrgAndId(String appDir, YamlMap android) {
    final oldAppId = android['override_old_package'] as String;
    final newAppId = android['package_name'] as String;
    final oldOrg = oldAppId.substring(0, oldAppId.lastIndexOf('.'));
    final newOrg = newAppId.substring(0, newAppId.lastIndexOf('.'));

    // The three native files this test's fixture (deliberately, see its
    // own dartdoc) doesn't include a full Android/Kotlin tree for — a
    // plain org/id substring swap is a faithful-enough stand-in for what
    // the real package_rename does to each of them.
    for (final relPath in [
      p.join('android', 'app', 'build.gradle.kts'),
      p.join('macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
      p.join('windows', 'runner', 'Runner.rc'),
    ]) {
      final file = File(p.join(appDir, relPath));
      if (!file.existsSync()) continue;
      file.writeAsStringSync(
        file
            .readAsStringSync()
            .replaceAll(oldAppId, newAppId)
            .replaceAll(oldOrg, newOrg),
      );
    }
  }

  void _rewriteLinuxCmake(String appDir, YamlMap config) {
    final linux = config['linux'] as YamlMap?;
    if (linux == null) return;
    final packageName = linux['package_name'] as String;
    final exeName = linux['exe_name'] as String;
    File(p.join(appDir, 'linux', 'CMakeLists.txt')).writeAsStringSync(
      'set(BINARY_NAME "$exeName")\n'
      'set(APPLICATION_ID "$packageName")\n',
    );
  }
}

const String _rootPubspec = '''
name: flutter_template_workspace
publish_to: none

environment:
  sdk: ^3.13.0

workspace:
  - apps/app
''';

const String _appPubspec = '''
name: app
description: "The flutter_template default app (rename via tooling:rename)."
publish_to: 'none'
''';

const String _buildGradleKts = '''
android {
    namespace = "com.example.app"
    defaultConfig {
        applicationId = "com.example.app"
    }
}
''';

const String _appInfoXcconfig = '''
PRODUCT_NAME = app
PRODUCT_BUNDLE_IDENTIFIER = com.example.app
PRODUCT_COPYRIGHT = Copyright © 2026 com.example. All rights reserved.
''';

const String _runnerRc = r'''
            VALUE "CompanyName", "com.example" "\0"
            VALUE "LegalCopyright", "Copyright (C) 2026 com.example. All rights reserved." "\0"
''';

const String _cmakeLists = '''
set(BINARY_NAME "app")
set(APPLICATION_ID "com.example.app")
''';

const String _i18nSource = '{\n  "appTitle": "flutter_template"\n}\n';

// Trimmed stand-ins for the real root NOTICE/CLA.md/CONTRIBUTING.md/
// SECURITY.md: each mixes a `flutter_template` body-text mention
// `rename` must rewrite with a `core/contracts/legal_facts`-style
// legal-identity placeholder ("Example GmbH", `security@example.com`) that
// must survive untouched — the same distinction the real files' own
// "Template placeholder, read before you ship" callouts document.
const String _noticeFile = '''
flutter_template
Copyright 2026 Example GmbH

This distribution includes software developed for the flutter_template
project, licensed under the Apache License, Version 2.0 — see LICENSE.
''';

const String _claFile = '''
Thank you for your interest in contributing to `flutter_template` (the "Project"), maintained by
**Example GmbH, Musterstraße 1, 12345 Berlin, Germany (the "Maintainer")**.

This file governs contributions to `flutter_template`.
''';

const String _contributingFile = '''
`flutter_template` is developed with GitHub issues.
''';

const String _securityFile = '''
This policy covers `flutter_template`.

Email the Maintainer directly at `security@example.com` with "Security:
flutter_template" in the subject.
''';

const String _websiteSiteConstants = '''
/// Doc comment.
const String productName = 'Your Product';

const String productTagline = 'Replace this with your own product tagline.';
''';

/// Builds a disposable git repo shaped just enough like the real
/// flutter_template for `RenameCommand` to run every rewrite step against:
/// only the files this command itself reads or writes — never a real
/// Android/iOS/Kotlin tree, since the native rewrite itself is
/// package_rename's job (faked above), not this command's.
Future<Directory> _buildFixtureRepoRoot({
  bool withAppImports = false,
  bool withWebsite = true,
  bool withChangelogs = false,
}) async {
  final repoRoot = Directory.systemTemp.createTempSync('rename_command_test_');
  if (withChangelogs) {
    for (final path in const [
      'CHANGELOG.md',
      'apps/app/CHANGELOG.md',
      'core/tooling/tooling/CHANGELOG.md',
    ]) {
      File(p.join(repoRoot.path, path))
        ..createSync(recursive: true)
        ..writeAsStringSync('- history of flutter_template\n');
    }
  }
  _writeFixtureFiles(
    repoRoot,
    withAppImports: withAppImports,
    withWebsite: withWebsite,
  );
  await _seedFixtureGitRepo(repoRoot);

  return repoRoot;
}

void _writeFixtureFiles(
  Directory repoRoot, {
  required bool withAppImports,
  bool withWebsite = true,
}) {
  void write(String relativePath, String content) {
    File(p.join(repoRoot.path, relativePath))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  write('pubspec.yaml', _rootPubspec);
  write('README.md', '# flutter_template\n\nA Flutter monorepo template.\n');
  write('CLAUDE.md', '# CLAUDE.md — flutter_template\n');
  write('apps/app/pubspec.yaml', _appPubspec);
  write('apps/app/README.md', '# app\n\nThe flutter_template default app.\n');
  write('NOTICE', _noticeFile);
  write('CLA.md', _claFile);
  write('CONTRIBUTING.md', _contributingFile);
  write('SECURITY.md', _securityFile);
  write('apps/app/android/app/build.gradle.kts', _buildGradleKts);
  write('apps/app/macos/Runner/Configs/AppInfo.xcconfig', _appInfoXcconfig);
  write('apps/app/windows/runner/Runner.rc', _runnerRc);
  write('apps/app/linux/CMakeLists.txt', _cmakeLists);
  write('apps/app/lib/i18n/en.i18n.json', _i18nSource);
  write('apps/app/lib/i18n/de.i18n.json', _i18nSource);
  if (withWebsite) {
    write('apps/website/lib/src/site_constants.dart', _websiteSiteConstants);
  }

  if (withAppImports) {
    const source = "import 'package:app/app/di.dart';\nvoid main() {}\n";
    write('apps/app/lib/main.dart', source);
    write('apps/app/test/app_test.dart', source);
  }
}

Future<void> _seedFixtureGitRepo(Directory repoRoot) async {
  const identity = [
    '-c',
    'user.name=Test',
    '-c',
    'user.email=test@example.com',
  ];
  await _git(repoRoot.path, ['init', '-q']);
  await _git(repoRoot.path, [...identity, 'add', '-A']);
  await _git(repoRoot.path, [
    ...identity,
    'commit',
    '-q',
    '-m',
    'chore(repo): seed fixture (#0)',
  ]);
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed: ${result.stdout}\n${result.stderr}',
    );
  }
}

/// Builds the flag list `RenameCommand` expects, overriding only what a
/// test cares about — cuts the boilerplate every test below would
/// otherwise repeat (and the `avoid_duplicate_code` lint that repetition
/// would trigger).
List<String> _renameArgs({
  String? appPackage,
  String name = 'acme_notes',
  String org = 'de.example',
  String display = 'Acme Notes',
}) => [
  '--name',
  name,
  '--org',
  org,
  '--display',
  display,
  if (appPackage != null) ...['--app-package', appPackage],
];

void main() {
  final buffer = StringBuffer();
  void out(String m) => buffer.writeln('OUT: $m');
  void err(String m) => buffer.writeln('ERR: $m');

  setUp(buffer.clear);

  Future<int> runRename(
    List<String> args, {
    required String repoRoot,
    ProcessRunner? runner,
  }) => RenameCommand(
    runner: runner ?? const SystemProcessRunner(),
    out: out,
    err: err,
  ).run(args, repoRoot: repoRoot);

  group('argument parsing', () {
    test('refuses missing required flags', () async {
      final exitCode = await runRename([
        '--name',
        'acme_notes',
      ], repoRoot: Directory.systemTemp.path);

      expect(exitCode, usageExitCode);
      expect(buffer.toString(), contains('Usage:'));
    });

    test('refuses an unknown flag', () async {
      final exitCode = await runRename([
        '--bogus',
        'x',
        ..._renameArgs(),
      ], repoRoot: Directory.systemTemp.path);

      expect(exitCode, usageExitCode);
      expect(buffer.toString(), contains('Unknown flag "--bogus"'));
    });

    final invalidCases = {
      'an invalid snake_case name': (
        args: _renameArgs(name: 'Acme-Notes'),
        message: '--name must be lowercase snake_case',
      ),
      'an invalid reverse-domain org': (
        args: _renameArgs(org: 'example'),
        message: '--org must be a reverse-domain',
      ),
      'an empty display name': (
        args: _renameArgs(display: '   '),
        message: '--display must not be empty',
      ),
    };
    for (final entry in invalidCases.entries) {
      test('refuses ${entry.key}', () async {
        final exitCode = await runRename(
          entry.value.args,
          repoRoot: Directory.systemTemp.path,
        );

        expect(exitCode, isNot(0));
        expect(buffer.toString(), contains(entry.value.message));
      });
    }
  });

  group('dirty tree refusal', () {
    test('refuses to run on an uncommitted change', () async {
      final repoRoot = await _buildFixtureRepoRoot();
      addTearDown(() => repoRoot.deleteSync(recursive: true));
      File(p.join(repoRoot.path, 'README.md')).writeAsStringSync('dirty\n');

      final exitCode = await runRename(
        _renameArgs(),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(),
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('Working tree is dirty'));
    });
  });

  group('happy path', () {
    test(
      'rewrites every Dart-level surface and runs post-rewrite checks',
      () async {
        final repoRoot = await _buildFixtureRepoRoot();
        addTearDown(() => repoRoot.deleteSync(recursive: true));
        final runner = _FakeRenameRunner();

        final exitCode = await runRename(
          _renameArgs(),
          repoRoot: repoRoot.path,
          runner: runner,
        );

        expect(exitCode, 0, reason: buffer.toString());
        _expectHappyPathFiles(repoRoot);
        expect(runner.fvmCalls.first, contains('package_rename'));
        expect(
          runner.fvmCalls.map((args) => args.join(' ')),
          containsAll([
            'dart pub get',
            'dart run melos run gen',
            'dart run melos run map',
            'dart run melos run analyze',
          ]),
        );
      },
    );
  });

  group('apps/website', () {
    test(
      'is a no-op (not an error) when the clone has no apps/website',
      () async {
        final repoRoot = await _buildFixtureRepoRoot(withWebsite: false);
        addTearDown(() => repoRoot.deleteSync(recursive: true));

        final exitCode = await runRename(
          _renameArgs(),
          repoRoot: repoRoot.path,
          runner: _FakeRenameRunner(),
        );

        expect(exitCode, 0, reason: buffer.toString());
      },
    );
  });

  group('--app-package', () {
    test('renames the Dart package and rewrites its own imports', () async {
      final repoRoot = await _buildFixtureRepoRoot(withAppImports: true);
      addTearDown(() => repoRoot.deleteSync(recursive: true));

      final exitCode = await runRename(
        _renameArgs(appPackage: 'acme_notes'),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(),
      );

      expect(exitCode, 0, reason: buffer.toString());
      _expectAppPackageRenamed(repoRoot);
    });

    test('refuses an invalid --app-package value', () async {
      final repoRoot = await _buildFixtureRepoRoot();
      addTearDown(() => repoRoot.deleteSync(recursive: true));

      final exitCode = await runRename(
        _renameArgs(appPackage: 'Bad-Name'),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(),
      );

      expect(exitCode, isNot(0));
      expect(
        buffer.toString(),
        contains('--app-package must be lowercase snake_case'),
      );
    });
  });

  group('subprocess failures', () {
    test('fails when package_rename itself fails', () async {
      final repoRoot = await _buildFixtureRepoRoot();
      addTearDown(() => repoRoot.deleteSync(recursive: true));

      final exitCode = await runRename(
        _renameArgs(),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(packageRenameExitCode: 1),
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('package_rename failed'));
      expect(
        File(p.join(repoRoot.path, 'apps', 'app', 'package_rename_config.yaml'))
            .existsSync(),
        isFalse,
        reason: 'the scratch config file must be cleaned up even on failure',
      );
    });

    test('fails when fvm dart pub get fails', () async {
      final repoRoot = await _buildFixtureRepoRoot();
      addTearDown(() => repoRoot.deleteSync(recursive: true));

      final exitCode = await runRename(
        _renameArgs(),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(pubGetExitCode: 1),
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('fvm dart pub get failed'));
    });

    test('fails when a post-rewrite melos script fails', () async {
      final repoRoot = await _buildFixtureRepoRoot();
      addTearDown(() => repoRoot.deleteSync(recursive: true));

      final exitCode = await runRename(
        _renameArgs(),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(melosExitCodes: const {'analyze': 1}),
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('melos run analyze failed'));
    });
  });

  group('leftover check', () {
    test('exempts changelogs at any depth', () async {
      final repoRoot = await _buildFixtureRepoRoot(withChangelogs: true);
      addTearDown(() => repoRoot.deleteSync(recursive: true));
      final exitCode = await runRename(
        _renameArgs(),
        repoRoot: repoRoot.path,
        runner: _FakeRenameRunner(),
      );

      expect(exitCode, 0, reason: buffer.toString());
      expect(
        File(p.join(repoRoot.path, 'apps/app/CHANGELOG.md')).readAsStringSync(),
        contains('flutter_template'),
      );
    });

    test(
      'fails loudly when package_rename silently skipped a platform',
      () async {
        final repoRoot = await _buildFixtureRepoRoot();
        addTearDown(() => repoRoot.deleteSync(recursive: true));

        final exitCode = await runRename(
          _renameArgs(),
          repoRoot: repoRoot.path,
          runner: _FakeRenameRunner(simulateLinuxCmakeUpdate: false),
        );

        expect(exitCode, isNot(0));
        expect(buffer.toString(), contains('old-name reference(s) behind'));
        expect(buffer.toString(), contains('linux/CMakeLists.txt'));
      },
    );
  });
}

void _expectHappyPathFiles(Directory repoRoot) {
  String read(String relativePath) =>
      File(p.join(repoRoot.path, relativePath)).readAsStringSync();

  expect(read('pubspec.yaml'), contains('name: acme_notes_workspace'));
  final appPubspec = read('apps/app/pubspec.yaml');
  expect(appPubspec, contains('name: app'));
  expect(appPubspec, contains('The acme_notes default app'));
  expect(read('README.md'), contains('# acme_notes'));
  expect(read('CLAUDE.md'), contains('# CLAUDE.md — acme_notes'));
  expect(read('apps/app/README.md'), contains('The acme_notes default app'));

  // NOTICE/CLA.md/CONTRIBUTING.md/SECURITY.md's body-text project-name
  // mentions are rewritten, but their legal-identity placeholders
  // (`core/contracts/legal_facts`' stand-ins, left for the README's "After
  // cloning" checklist) are not touched by rename.
  final notice = read('NOTICE');
  expect(notice, isNot(contains('flutter_template')));
  expect(notice, contains('acme_notes'));
  expect(notice, contains('Example GmbH'));

  final cla = read('CLA.md');
  expect(cla, isNot(contains('flutter_template')));
  expect(cla, contains('contributing to `acme_notes`'));
  expect(cla, contains('governs contributions to `acme_notes`.'));
  expect(cla, contains('Example GmbH, Musterstraße 1, 12345 Berlin, Germany'));

  final contributing = read('CONTRIBUTING.md');
  expect(contributing, isNot(contains('flutter_template')));
  expect(
    contributing,
    contains('`acme_notes` is developed with GitHub issues'),
  );

  final security = read('SECURITY.md');
  expect(security, isNot(contains('flutter_template')));
  expect(security, contains('This policy covers `acme_notes`.'));
  expect(security, contains('security@example.com'));
  expect(
    read('apps/app/lib/i18n/en.i18n.json'),
    contains('"appTitle": "Acme Notes"'),
  );
  expect(
    read('apps/website/lib/src/site_constants.dart'),
    contains("const String productName = 'Acme Notes';"),
  );

  final desktopEntry = read('apps/app/linux/app.desktop');
  expect(desktopEntry, contains('Name=Acme Notes'));
  expect(desktopEntry, contains('Exec=acme_notes'));
  expect(desktopEntry, contains('Icon=de.example.acme_notes'));

  expect(
    File(p.join(repoRoot.path, 'apps', 'app', 'package_rename_config.yaml'))
        .existsSync(),
    isFalse,
    reason: 'the scratch package_rename_config.yaml must be cleaned up',
  );
}

void _expectAppPackageRenamed(Directory repoRoot) {
  String read(String relativePath) =>
      File(p.join(repoRoot.path, relativePath)).readAsStringSync();

  expect(read('apps/app/pubspec.yaml'), contains('name: acme_notes'));
  const expectedImport = "import 'package:acme_notes/app/di.dart';";
  expect(read('apps/app/lib/main.dart'), contains(expectedImport));
  expect(read('apps/app/test/app_test.dart'), contains(expectedImport));
}
