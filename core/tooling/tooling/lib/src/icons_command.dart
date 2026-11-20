import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/icon_image_generation.dart';
import 'package:tooling/src/index_html_icon_patch.dart';
import 'package:tooling/src/linux_cmake_ids.dart';
import 'package:tooling/src/linux_desktop_entry.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:yaml/yaml.dart';

/// The number of positional arguments `icons` takes: none.
const int _expectedArgCount = 0;

/// See `verification_suite.dart`'s identical constant for the full
/// rationale — suppresses Dart/Flutter tooling telemetry for the
/// generator subprocesses below.
const String _suppressAnalyticsEnvVar = 'DASH__SUPPRESS_ANALYTICS';
const Map<String, String> _generatorEnvironment = {
  _suppressAnalyticsEnvVar: 'true',
};

/// The Linux hicolor icon-theme sizes [IconsCommand] installs: 256 (also
/// backs the runtime window icon `linux/runner/my_application.cc` loads —
/// see `linux/CMakeLists.txt`'s install rules) and 512 (a
/// higher-resolution variant for large-icon desktop launchers).
const List<int> linuxIconSizes = <int>[256, 512];

/// `icons`: regenerates every platform launcher icon and splash screen
/// from `apps/app/assets/icon/*.png` (see that directory's README.md for
/// the source-image requirements).
///
/// Runs flutter_launcher_icons then flutter_native_splash inside
/// `apps/app` (via `fvm dart run ...`, through the injected
/// [ProcessRunner] so tests never shell out for real — see
/// `icons_command_test.dart`), then fills the gaps neither package covers:
/// `web/favicon.ico` (16/32/48), `web/apple-touch-icon.png` (180x180), the
/// Linux launcher icon + `.desktop` entry, and idempotent
/// `web/index.html` link-tag patching. Usage: `fvm dart run tooling:icons`
/// (also wired as the `icons` melos script — see root `pubspec.yaml`).
class IconsCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; tests
  /// override them to capture output instead of printing it.
  IconsCommand({
    required this.runner,
    this.out = _defaultOut,
    this.err = _defaultErr,
  });

  /// The process runner flutter_launcher_icons/flutter_native_splash are
  /// invoked through.
  final ProcessRunner runner;

  /// Sink for normal progress messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);

  /// Runs the command against the repository rooted at [repoRoot] (its
  /// `apps/app` subdirectory is where every generator and gap-fill step
  /// actually operates). Returns the process exit code.
  Future<int> run(List<String> args, {required String repoRoot}) =>
      runCatchingFailures(() => _run(args, repoRoot), err);

  Future<void> _run(List<String> args, String repoRoot) async {
    if (args.length != _expectedArgCount) {
      throw CommandFailure('Usage: icons', exitCode: usageExitCode);
    }
    final appDir = p.join(repoRoot, 'apps', 'app');

    await _runGenerator(appDir, 'flutter_launcher_icons', [
      'flutter_launcher_icons',
    ]);
    await _runGenerator(appDir, 'flutter_native_splash', [
      'flutter_native_splash:create',
    ]);

    final source = _loadSourceIcon(appDir);
    _writeWebGaps(appDir, source);
    _writeLinuxGaps(appDir, source);

    out(
      'icons: regenerated every platform launcher icon and splash screen, '
      'and filled the web/Linux gaps.',
    );
  }

  Future<void> _runGenerator(
    String appDir,
    String label,
    List<String> generatorArgs,
  ) async {
    out('Running $label...');
    final result = await runner.run(
      'fvm',
      ['dart', 'run', ...generatorArgs],
      workingDirectory: appDir,
      environment: _generatorEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        '$label failed:\n${result.stdout}\n${result.stderr}',
      );
    }
  }

  img.Image _loadSourceIcon(String appDir) {
    final file = File(p.join(appDir, 'assets', 'icon', 'icon.png'));
    if (!file.existsSync()) {
      throw CommandFailure(
        '${file.path} not found — see apps/app/assets/icon/README.md.',
      );
    }
    final decoded = img.decodePng(file.readAsBytesSync());
    if (decoded == null) {
      throw CommandFailure('${file.path} could not be decoded as a PNG.');
    }

    return decoded;
  }

  void _writeWebGaps(String appDir, img.Image source) {
    final webDir = p.join(appDir, 'web');
    File(p.join(webDir, 'favicon.ico'))
        .writeAsBytesSync(generateFaviconIco(source));
    File(p.join(webDir, 'apple-touch-icon.png'))
        .writeAsBytesSync(generateAppleTouchIcon(source));
    _patchIndexHtml(webDir);
    out(
      'Wrote web/favicon.ico, web/apple-touch-icon.png and patched '
      'web/index.html.',
    );
  }

  void _patchIndexHtml(String webDir) {
    final indexFile = File(p.join(webDir, 'index.html'));
    try {
      final patched = patchIndexHtmlIconTags(indexFile.readAsStringSync());
      // Absorbs flutter_native_splash's own non-idempotent whitespace —
      // see normalizeIndexHtmlBlankLines's dartdoc.
      indexFile.writeAsStringSync(normalizeIndexHtmlBlankLines(patched));
    } on FormatException catch (e) {
      throw CommandFailure('${indexFile.path}: $e');
    }
  }

  void _writeLinuxGaps(String appDir, img.Image source) {
    final resourcesDir = Directory(
      p.join(appDir, 'linux', 'runner', 'resources'),
    )..createSync(recursive: true);
    for (final size in linuxIconSizes) {
      File(p.join(resourcesDir.path, 'app_icon_$size.png'))
          .writeAsBytesSync(generateLinuxIconPng(source, size: size));
    }
    _writeLinuxDesktopEntry(appDir);
    final sizeList = linuxIconSizes.join(',');
    out(
      'Wrote linux/runner/resources/app_icon_{$sizeList}.png '
      'and linux/app.desktop.',
    );
  }

  void _writeLinuxDesktopEntry(String appDir) {
    final cmakeFile = File(p.join(appDir, 'linux', 'CMakeLists.txt'));
    final LinuxCmakeIds ids;
    try {
      ids = readLinuxCmakeIds(cmakeFile.readAsStringSync());
    } on FormatException catch (e) {
      throw CommandFailure('${cmakeFile.path}: $e');
    }
    final entry = buildLinuxDesktopEntry(
      name: _readAppName(appDir),
      execName: ids.binaryName,
      iconId: ids.applicationId,
    );
    File(p.join(appDir, 'linux', 'app.desktop')).writeAsStringSync(entry);
  }

  String _readAppName(String appDir) {
    final pubspecFile = File(p.join(appDir, 'pubspec.yaml'));
    final doc = loadYaml(pubspecFile.readAsStringSync());
    final name = doc is YamlMap ? doc['name'] as String? : null;
    if (name == null) {
      throw CommandFailure('${pubspecFile.path} has no "name:".');
    }

    return name;
  }
}
