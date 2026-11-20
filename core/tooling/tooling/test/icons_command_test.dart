import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/icon_image_generation.dart';
import 'package:tooling/src/icons_command.dart';
import 'package:tooling/src/process_runner.dart';

/// Fakes both external generators `IconsCommand` shells out to
/// (flutter_launcher_icons, flutter_native_splash) so this test exercises
/// only the command's own gap-fill logic against a real, disposable
/// `apps/app`-shaped fixture directory — never a real FVM/Flutter
/// toolchain. Refuses any other executable, so a bug that shells out to
/// something unexpected fails loudly instead of silently.
//
// This file is named for the command under test, not for this private fake
// ProcessRunner (the only class declared here) — matches
// gen_fresh_check_command_test.dart's `_FakeFvmRunner` convention.
// ignore: solid_lints/prefer_match_file_name
class _FakeGeneratorRunner implements ProcessRunner {
  _FakeGeneratorRunner({
    this.launcherIconsExitCode = 0,
    this.nativeSplashExitCode = 0,
  });

  final int launcherIconsExitCode;
  final int nativeSplashExitCode;

  final List<List<String>> fvmCalls = <List<String>>[];
  final List<String?> workingDirectories = <String?>[];
  final List<Map<String, String>?> environments = <Map<String, String>?>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (executable != 'fvm') {
      throw StateError('unexpected executable: $executable $arguments');
    }
    fvmCalls.add(arguments);
    workingDirectories.add(workingDirectory);
    environments.add(environment);

    if (arguments.contains('flutter_launcher_icons')) {
      return ProcessResult(
        0,
        launcherIconsExitCode,
        '',
        launcherIconsExitCode == 0 ? '' : 'flutter_launcher_icons failed',
      );
    }
    if (arguments.contains('flutter_native_splash:create')) {
      if (nativeSplashExitCode == 0 && workingDirectory != null) {
        // The real flutter_native_splash leaves a few stray whitespace-only
        // blank lines in web/index.html on every run — confirmed
        // empirically (see normalizeIndexHtmlBlankLines' dartdoc).
        // Simulated here so this fake exercises the same idempotency
        // concern the real tool does.
        _appendStrayBlankLines(p.join(workingDirectory, 'web', 'index.html'));
      }

      return ProcessResult(
        0,
        nativeSplashExitCode,
        '',
        nativeSplashExitCode == 0 ? '' : 'flutter_native_splash failed',
      );
    }
    throw StateError('unexpected fvm call: $arguments');
  }
}

void _appendStrayBlankLines(String indexHtmlPath) {
  final file = File(indexHtmlPath);
  if (!file.existsSync()) return;
  file.writeAsStringSync('${file.readAsStringSync()}  \n  \n');
}

const String _sampleIndexHtml = '''
<head>
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>app</title>
</head>
''';

const String _sampleCmakeLists = '''
set(BINARY_NAME "app")
set(APPLICATION_ID "de.example.app")
''';

/// Dimensions and colour for the fixture source icon [_buildFixtureRepoRoot]
/// writes — arbitrary, named so neither is a bare literal at the call site.
const int _fixtureIconSize = 64;
const int _fixtureColorRed = 29;
const int _fixtureColorGreen = 111;
const int _fixtureColorBlue = 224;

/// Builds a disposable directory shaped like the repo root, with just
/// enough of `apps/app` for [IconsCommand] to run its gap-fill steps
/// against: a source `assets/icon/icon.png`, `web/index.html`,
/// `linux/CMakeLists.txt` and `pubspec.yaml`.
Directory _buildFixtureRepoRoot() {
  final repoRoot = Directory.systemTemp.createTempSync('icons_command_test_');
  final appDir = Directory(p.join(repoRoot.path, 'apps', 'app'))
    ..createSync(recursive: true);

  final iconDir = Directory(p.join(appDir.path, 'assets', 'icon'))
    ..createSync(recursive: true);
  final sourceIcon =
      img.Image(width: _fixtureIconSize, height: _fixtureIconSize)..clear(
        img.ColorRgb8(_fixtureColorRed, _fixtureColorGreen, _fixtureColorBlue),
      );
  File(p.join(iconDir.path, 'icon.png'))
      .writeAsBytesSync(img.encodePng(sourceIcon));

  Directory(p.join(appDir.path, 'web')).createSync(recursive: true);
  File(p.join(appDir.path, 'web', 'index.html'))
      .writeAsStringSync(_sampleIndexHtml);

  Directory(p.join(appDir.path, 'linux')).createSync(recursive: true);
  File(p.join(appDir.path, 'linux', 'CMakeLists.txt'))
      .writeAsStringSync(_sampleCmakeLists);

  File(p.join(appDir.path, 'pubspec.yaml'))
      .writeAsStringSync('name: app\ndescription: test fixture\n');

  return repoRoot;
}

/// A repo-root fixture plus the fake runner [IconsCommand] runs against —
/// built fresh per happy-path test (no shared `setUp`/`tearDown` state, so
/// no `late` fields — see CLAUDE.md's solid_lints row).
class _HappyPathFixture {
  _HappyPathFixture()
    : repoRoot = _buildFixtureRepoRoot(),
      runner = _FakeGeneratorRunner();

  final Directory repoRoot;
  final _FakeGeneratorRunner runner;

  /// A getter, not a stored field — it only needs [repoRoot], set in the
  /// initializer list above, so there's no need for a `late` field just to
  /// defer its computation past construction.
  String get appDir => p.join(repoRoot.path, 'apps', 'app');

  void dispose() => repoRoot.deleteSync(recursive: true);
}

void main() {
  final buffer = StringBuffer();
  void out(String m) => buffer.writeln('OUT: $m');
  void err(String m) => buffer.writeln('ERR: $m');

  setUp(buffer.clear);

  test('refuses arguments', () async {
    final command = IconsCommand(
      runner: _FakeGeneratorRunner(),
      out: out,
      err: err,
    );

    final exitCode = await command.run([
      'unexpected',
    ], repoRoot: Directory.systemTemp.path);

    expect(exitCode, usageExitCode);
  });

  test('fails when flutter_launcher_icons fails', () async {
    final repoRoot = _buildFixtureRepoRoot();
    addTearDown(() => repoRoot.deleteSync(recursive: true));
    final runner = _FakeGeneratorRunner(launcherIconsExitCode: 1);
    final command = IconsCommand(runner: runner, out: out, err: err);

    final exitCode = await command.run([], repoRoot: repoRoot.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('flutter_launcher_icons failed'));
  });

  test('fails when flutter_native_splash fails', () async {
    final repoRoot = _buildFixtureRepoRoot();
    addTearDown(() => repoRoot.deleteSync(recursive: true));
    final runner = _FakeGeneratorRunner(nativeSplashExitCode: 1);
    final command = IconsCommand(runner: runner, out: out, err: err);

    final exitCode = await command.run([], repoRoot: repoRoot.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('flutter_native_splash failed'));
  });

  test(
    'fails with a clear message when assets/icon/icon.png is missing',
    () async {
      final repoRoot = _buildFixtureRepoRoot();
      addTearDown(() => repoRoot.deleteSync(recursive: true));
      File(p.join(repoRoot.path, 'apps', 'app', 'assets', 'icon', 'icon.png'))
          .deleteSync();
      final command = IconsCommand(
        runner: _FakeGeneratorRunner(),
        out: out,
        err: err,
      );

      final exitCode = await command.run([], repoRoot: repoRoot.path);

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('icon.png'));
    },
  );

  test('happy path: runs flutter_launcher_icons then flutter_native_splash '
      'inside apps/app, with analytics suppressed', () async {
    final fixture = _HappyPathFixture();
    addTearDown(fixture.dispose);
    final command = IconsCommand(runner: fixture.runner, out: out, err: err);

    final exitCode = await command.run([], repoRoot: fixture.repoRoot.path);

    expect(exitCode, 0, reason: buffer.toString());
    expect(fixture.runner.fvmCalls, [
      ['dart', 'run', 'flutter_launcher_icons'],
      ['dart', 'run', 'flutter_native_splash:create'],
    ]);
    expect(fixture.runner.workingDirectories, [fixture.appDir, fixture.appDir]);
    for (final environment in fixture.runner.environments) {
      expect(environment, {'DASH__SUPPRESS_ANALYTICS': 'true'});
    }
  });

  test('happy path: writes favicon.ico (16/32/48) and apple-touch-icon.png '
      '(180x180, no alpha)', () async {
    final fixture = _HappyPathFixture();
    addTearDown(fixture.dispose);
    final command = IconsCommand(runner: fixture.runner, out: out, err: err);
    await command.run([], repoRoot: fixture.repoRoot.path);

    final ico = img.IcoDecoder().decode(
      File(p.join(fixture.appDir, 'web', 'favicon.ico')).readAsBytesSync(),
    );
    if (ico == null) {
      fail('web/favicon.ico must decode as ICO');
    }
    final frameSizes = ico.frames.map((f) => f.width).toList()..sort();
    expect(frameSizes, [...faviconIcoSizes]..sort());

    final touchIcon = img.decodePng(
      File(p.join(fixture.appDir, 'web', 'apple-touch-icon.png'))
          .readAsBytesSync(),
    );
    if (touchIcon == null) {
      fail('web/apple-touch-icon.png must decode as PNG');
    }
    expect(touchIcon.width, appleTouchIconSize);
    expect(touchIcon.height, appleTouchIconSize);
    expect(touchIcon.hasAlpha, isFalse);
  });

  test('happy path: patches web/index.html idempotently', () async {
    final fixture = _HappyPathFixture();
    addTearDown(fixture.dispose);
    final command = IconsCommand(runner: fixture.runner, out: out, err: err);
    await command.run([], repoRoot: fixture.repoRoot.path);

    final indexFile = File(p.join(fixture.appDir, 'web', 'index.html'));
    final firstPass = indexFile.readAsStringSync();
    expect(firstPass, contains('apple-touch-icon.png'));
    expect(firstPass, contains('favicon.ico'));

    await command.run([], repoRoot: fixture.repoRoot.path);
    final secondPass = indexFile.readAsStringSync();
    expect(secondPass, firstPass);
  });

  test(
    'happy path: writes the Linux icon PNGs (256/512) and app.desktop',
    () async {
      final fixture = _HappyPathFixture();
      addTearDown(fixture.dispose);
      final command = IconsCommand(runner: fixture.runner, out: out, err: err);
      await command.run([], repoRoot: fixture.repoRoot.path);

      for (final size in linuxIconSizes) {
        final decoded = img.decodePng(
          File(
            p.join(
              fixture.appDir,
              'linux',
              'runner',
              'resources',
              'app_icon_$size.png',
            ),
          ).readAsBytesSync(),
        );
        if (decoded == null) {
          fail('linux app_icon_$size.png must decode as PNG');
        }
        expect(decoded.width, size);
        expect(decoded.height, size);
      }

      final desktopEntry = File(p.join(fixture.appDir, 'linux', 'app.desktop'))
          .readAsStringSync();
      expect(desktopEntry, contains('Name=app'));
      expect(desktopEntry, contains('Exec=app'));
      expect(desktopEntry, contains('Icon=de.example.app'));
    },
  );

  test('happy path: running twice leaves the generated tree byte-identical '
      '(besides the fvm call log)', () async {
    final fixture = _HappyPathFixture();
    addTearDown(fixture.dispose);
    final command = IconsCommand(runner: fixture.runner, out: out, err: err);
    await command.run([], repoRoot: fixture.repoRoot.path);
    final firstDesktopEntry = File(
      p.join(fixture.appDir, 'linux', 'app.desktop'),
    ).readAsStringSync();
    final firstFavicon = File(p.join(fixture.appDir, 'web', 'favicon.ico'))
        .readAsBytesSync();
    final firstIndexHtml = File(p.join(fixture.appDir, 'web', 'index.html'))
        .readAsStringSync();

    await command.run([], repoRoot: fixture.repoRoot.path);
    final secondDesktopEntry = File(
      p.join(fixture.appDir, 'linux', 'app.desktop'),
    ).readAsStringSync();
    final secondFavicon = File(p.join(fixture.appDir, 'web', 'favicon.ico'))
        .readAsBytesSync();
    final secondIndexHtml = File(p.join(fixture.appDir, 'web', 'index.html'))
        .readAsStringSync();

    expect(secondDesktopEntry, firstDesktopEntry);
    expect(secondFavicon, firstFavicon);
    // The fake flutter_native_splash appends stray blank lines on every
    // call (see _appendStrayBlankLines) — this asserts
    // normalizeIndexHtmlBlankLines absorbs that, the same real
    // non-idempotency `melos run icons` hits twice in a row.
    expect(secondIndexHtml, firstIndexHtml);
  });
}
