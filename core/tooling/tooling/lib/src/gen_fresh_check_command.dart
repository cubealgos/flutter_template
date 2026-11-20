import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/fvmrc.dart';
import 'package:tooling/src/process_runner.dart';

/// The number of positional arguments `gen_fresh_check` takes: none.
const int _expectedArgCount = 0;

/// The environment variable that suppresses Dart/Flutter tooling telemetry
/// for one process tree — see the root `pubspec.yaml`'s `gen-fresh-check`
/// script description and `verification_suite.dart`'s own use of it.
const String _suppressAnalyticsEnvVar = 'DASH__SUPPRESS_ANALYTICS';
const Map<String, String> _checkEnvironment = {
  _suppressAnalyticsEnvVar: 'true',
};

/// `gen-fresh-check`: reproduces a CI-style fresh clone end to end and
/// fails unless it reproduces HEAD exactly.
///
/// Clones [run]'s `repoRoot` argument's current HEAD into a fresh temp
/// directory (a real `git clone`, so only what's committed is present —
/// never the working tree's uncommitted state, and never an existing
/// `.dart_tool/build` cache), links that clone to the same
/// `.fvmrc`-pinned FVM Flutter SDK `branch_new` links a new worktree to,
/// runs `pub get` then `melos run gen` there, and fails unless the result
/// is byte-identical to what's committed (`git status --porcelain` empty).
///
/// Exists because `melos run check-generated` alone reruns `gen` inside
/// *this* checkout, which may already have a warm `.dart_tool/build`
/// cache from a previous run — exactly the condition that let a
/// `$lib$`-keyed slang_build_runner output pass locally while failing on
/// every genuinely fresh clone or CI checkout. This command has
/// no such cache to fall back on, by construction.
///
/// Always deletes its temp clone before returning, pass or fail.
class GenFreshCheckCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; tests
  /// override them to capture output instead of printing it.
  GenFreshCheckCommand({
    required this.runner,
    this.out = _defaultOut,
    this.err = _defaultErr,
  });

  /// The process runner `git`/`fvm` are invoked through.
  final ProcessRunner runner;

  /// Sink for normal progress messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);

  /// Runs the command against the repository rooted at [repoRoot] (either
  /// the main checkout or a worktree — the clone below reproduces
  /// whichever one is current, following its `HEAD`). Returns the process
  /// exit code.
  Future<int> run(List<String> args, {required String repoRoot}) =>
      runCatchingFailures(() => _run(args, repoRoot), err);

  Future<void> _run(List<String> args, String repoRoot) async {
    if (args.length != _expectedArgCount) {
      throw CommandFailure('Usage: gen_fresh_check', exitCode: usageExitCode);
    }

    final absoluteRepoRoot = p.absolute(repoRoot);
    final version = readFvmrcVersion(absoluteRepoRoot);
    final tempDir = Directory.systemTemp.createTempSync('gen_fresh_check_');
    try {
      final cloneDir = p.join(tempDir.path, 'clone');
      await _clone(absoluteRepoRoot, cloneDir);
      await _linkFvm(cloneDir, version);
      await _pubGet(cloneDir);
      await _gen(cloneDir);
      await _checkClean(cloneDir);
      out(
        'gen-fresh-check passed: a fresh clone of HEAD, after pub get + '
        'melos run gen, matches HEAD exactly.',
      );
    } finally {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    }
  }

  Future<void> _clone(String repoRoot, String cloneDir) async {
    final result = await runner.run('git', [
      'clone',
      '--quiet',
      repoRoot,
      cloneDir,
    ]);
    if (result.exitCode != 0) {
      throw CommandFailure(
        'git clone $repoRoot failed: ${result.stdout}\n${result.stderr}',
      );
    }
  }

  Future<void> _linkFvm(String cloneDir, String version) async {
    // See `branch_new`'s own `_setUpFvm`: `--force` matters even for a
    // freshly cloned, never-before-used directory — without it `fvm`
    // refuses outright on an unrecognized project shape rather than just
    // proceeding.
    final result = await runner.run(
      'fvm',
      ['use', version, '--skip-pub-get', '--force'],
      workingDirectory: cloneDir,
      environment: _checkEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        'fvm use $version failed in the fresh clone: '
        '${result.stdout}\n${result.stderr}',
      );
    }
    if (!fvmSdkLinked(cloneDir)) {
      throw CommandFailure(
        "fvm use $version reported success, but the fresh clone's "
        '.fvm/flutter_sdk/bin/dart does not resolve.',
      );
    }
    await _precache(cloneDir, version);
  }

  /// Runs `fvm flutter precache` once — the Flutter tool's own documented
  /// command for populating `<sdk>/bin/cache/pkg/` (including `sky_engine`,
  /// the SDK-bundled pub package `flutter`/`flutter_test`/etc. resolve
  /// against) and the engine binaries. A never-before-used FVM-managed SDK
  /// install doesn't have that cache populated yet (only `fvm use` was
  /// run, which just links the SDK directory — it never itself invokes
  /// `flutter`), so the [_pubGet] step right after this would otherwise
  /// fail resolving `sky_engine from sdk` ("could not find package
  /// sky_engine in the Flutter SDK"). `fvm flutter --version` was tried
  /// first and does *not* fix this — confirmed on a real CI run,
  /// it exits 0 without populating `bin/cache/pkg/` — `precache`
  /// is the command actually documented to do this. Never reproduces on a
  /// developer's machine, where that version's `~/fvm/versions/<version>`
  /// cache is already warm from ordinary everyday use.
  Future<void> _precache(String cloneDir, String version) async {
    final result = await runner.run(
      'fvm',
      ['flutter', 'precache'],
      workingDirectory: cloneDir,
      environment: _checkEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        'fvm flutter precache failed to warm up the $version SDK cache '
        'in the fresh clone: ${result.stdout}\n${result.stderr}',
      );
    }
  }

  Future<void> _pubGet(String cloneDir) async {
    // A single `dart pub get` at the workspace root resolves every member
    // in one pass (`resolution: workspace` — see each member's
    // pubspec.yaml and the root pubspec.yaml's `workspace:` list).
    final result = await runner.run(
      'fvm',
      ['dart', 'pub', 'get'],
      workingDirectory: cloneDir,
      environment: _checkEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        'fvm dart pub get failed in the fresh clone: '
        '${result.stdout}\n${result.stderr}',
      );
    }
  }

  Future<void> _gen(String cloneDir) async {
    final result = await runner.run(
      'fvm',
      ['dart', 'run', 'melos', 'run', 'gen'],
      workingDirectory: cloneDir,
      environment: _checkEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        'melos run gen failed in the fresh clone (this is the failure a '
        'real fresh clone or CI checkout would hit): '
        '${result.stdout}\n${result.stderr}',
      );
    }
  }

  Future<void> _checkClean(String cloneDir) async {
    final result = await runner.run('git', [
      'status',
      '--porcelain',
    ], workingDirectory: cloneDir);
    if (result.exitCode != 0) {
      throw CommandFailure(
        'git status --porcelain failed in the fresh clone: '
        '${result.stdout}\n${result.stderr}',
      );
    }
    final dirty = (result.stdout as String).trim();
    if (dirty.isNotEmpty) {
      throw CommandFailure(
        'melos run gen changed the tree on a fresh clone — it is not '
        'reproducible from HEAD alone:\n$dirty',
      );
    }
  }
}
