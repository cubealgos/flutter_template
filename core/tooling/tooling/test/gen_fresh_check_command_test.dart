import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/gen_fresh_check_command.dart';
import 'package:tooling/src/process_runner.dart';

import 'support/git_fixture.dart';

/// A marker written, uncommitted, into a fixture file — used to prove the
/// command's clone reflects only committed `HEAD`, never the source
/// checkout's dirty working tree.
const String _uncommittedMarker = 'UNCOMMITTED_MARKER';

/// A [ProcessRunner] that passes `git` straight through to the real
/// binary (cloning and status-checking a real local git fixture is cheap
/// and exactly what's under test) but fakes every `fvm` call, so tests
/// never depend on a real FVM install or a real `melos`/`build_runner`
/// run. Records the working directory every `fvm` call ran in — the
/// fresh clone's own directory — so tests can assert it's deleted again
/// once the command returns.
//
// This file is named for the command under test, not for this private fake
// ProcessRunner (the only class declared here).
// ignore: solid_lints/prefer_match_file_name
class _FakeFvmRunner implements ProcessRunner {
  _FakeFvmRunner({
    this.genExitCode = 0,
    this.genOutput = '',
    this.genWritesStrayFile = false,
    this.createSdkLink = true,
    this.genRejectsUncommittedMarker = false,
    this.precacheExitCode = 0,
  });

  final int genExitCode;
  final String genOutput;
  final bool genWritesStrayFile;
  final bool createSdkLink;
  final bool genRejectsUncommittedMarker;
  final int precacheExitCode;

  final List<List<String>> fvmCalls = <List<String>>[];
  String? lastCloneDir;

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
    // Every real `fvm` call GenFreshCheckCommand makes passes a
    // workingDirectory (the fresh clone) — a null here would itself be a
    // bug in the command under test, so this throws rather than silently
    // tolerating it, and lets the rest of this method treat `cloneDir` as
    // non-nullable.
    final cloneDir = workingDirectory;
    if (cloneDir == null) {
      throw StateError('fvm call without a working directory: $arguments');
    }

    fvmCalls.add(arguments);
    lastCloneDir = cloneDir;
    final joined = arguments.join(' ');

    if (arguments.first == 'use') {
      if (createSdkLink) {
        File(p.join(cloneDir, '.fvm', 'flutter_sdk', 'bin', 'dart'))
            .createSync(recursive: true);
      }

      return ProcessResult(0, 0, '', '');
    }
    if (arguments.first == 'flutter') {
      return ProcessResult(0, precacheExitCode, '', 'precache failed');
    }
    if (joined == 'dart pub get') {
      return ProcessResult(0, 0, '', '');
    }
    if (joined == 'dart run melos run gen') {
      return _runGen(cloneDir);
    }
    throw StateError('unexpected fvm call: $arguments');
  }

  ProcessResult _runGen(String cloneDir) {
    if (genRejectsUncommittedMarker) {
      final readme = File(p.join(cloneDir, 'README.md')).readAsStringSync();
      if (readme.contains(_uncommittedMarker)) {
        return ProcessResult(0, 1, 'uncommitted marker leaked into clone', '');
      }
    }
    if (genWritesStrayFile) {
      File(p.join(cloneDir, 'stray_generated.dart'))
          .writeAsStringSync('// stray\n');
    }

    return ProcessResult(0, genExitCode, genOutput, '');
  }
}

/// [runner]'s last recorded fresh-clone directory, asserting it was set —
/// every test that calls this has already run a [GenFreshCheckCommand]
/// that reaches at least one `fvm` call, so a `null` here would itself be
/// a test bug worth failing loudly on, not a case to route around.
String _cloneDirOf(_FakeFvmRunner runner) {
  final dir = runner.lastCloneDir;
  expect(dir, isNotNull);

  // The expect() above already fails the test if dir is null.
  // ignore: solid_lints/avoid_non_null_assertion
  return dir!;
}

void main() {
  final buffer = StringBuffer();
  void out(String m) => buffer.writeln('OUT: $m');
  void err(String m) => buffer.writeln('ERR: $m');

  setUp(buffer.clear);

  test('refuses the wrong number of arguments', () async {
    final command = GenFreshCheckCommand(
      runner: const SystemProcessRunner(),
      out: out,
      err: err,
    );

    final exitCode = await command.run([
      'unexpected',
    ], repoRoot: Directory.systemTemp.path);

    expect(exitCode, usageExitCode);
  });

  test('refuses when .fvmrc is missing from repoRoot', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    File(p.join(fixture.mainCheckout.path, '.fvmrc')).deleteSync();

    final command = GenFreshCheckCommand(
      runner: const SystemProcessRunner(),
      out: out,
      err: err,
    );
    final exitCode = await command.run([], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('.fvmrc not found'));
  });

  test('happy path: clones HEAD, links the .fvmrc SDK, runs pub get + gen, '
      'and cleans up the clone', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final runner = _FakeFvmRunner();

    final command = GenFreshCheckCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, 0, reason: buffer.toString());
    expect(runner.fvmCalls, [
      ['use', fixtureFlutterVersion, '--skip-pub-get', '--force'],
      ['flutter', 'precache'],
      ['dart', 'pub', 'get'],
      ['dart', 'run', 'melos', 'run', 'gen'],
    ]);
    final cloneDir = _cloneDirOf(runner);
    expect(
      Directory(cloneDir).existsSync(),
      isFalse,
      reason: 'the temp clone must be deleted once the command returns',
    );
    expect(
      Directory(p.dirname(cloneDir)).existsSync(),
      isFalse,
      reason:
          'the whole temp directory must be deleted, not just the '
          'clone subdirectory',
    );
  });

  test("clones only committed HEAD, never the source checkout's uncommitted "
      'changes', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    File(p.join(fixture.mainCheckout.path, 'README.md'))
        .writeAsStringSync('$_uncommittedMarker\n');
    final runner = _FakeFvmRunner(genRejectsUncommittedMarker: true);

    final command = GenFreshCheckCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, 0, reason: buffer.toString());
  });

  test('fails when melos run gen itself fails', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final runner = _FakeFvmRunner(
      genExitCode: 1,
      genOutput: 'InvalidOutputException: Asset already exists',
    );

    final command = GenFreshCheckCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('melos run gen failed'));
    expect(
      buffer.toString(),
      contains('InvalidOutputException: Asset already exists'),
    );
    expect(
      Directory(_cloneDirOf(runner)).existsSync(),
      isFalse,
      reason: 'the temp clone must be deleted even on failure',
    );
  });

  test('fails when gen leaves the fresh clone dirty (not reproducible from '
      'HEAD alone)', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final runner = _FakeFvmRunner(genWritesStrayFile: true);

    final command = GenFreshCheckCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('not reproducible from HEAD'));
    expect(buffer.toString(), contains('stray_generated.dart'));
  });

  test(
    'fails loudly when fvm use succeeds but the SDK link does not resolve',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final runner = _FakeFvmRunner(createSdkLink: false);

      final command = GenFreshCheckCommand(runner: runner, out: out, err: err);
      final exitCode = await command.run(
        [],
        repoRoot: fixture.mainCheckout.path,
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('does not resolve'));
    },
  );

  test(
    'fails loudly when fvm flutter precache fails to warm the SDK cache',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final runner = _FakeFvmRunner(precacheExitCode: 1);

      final command = GenFreshCheckCommand(runner: runner, out: out, err: err);
      final exitCode = await command.run(
        [],
        repoRoot: fixture.mainCheckout.path,
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('warm up'));
      expect(runner.fvmCalls, [
        ['use', fixtureFlutterVersion, '--skip-pub-get', '--force'],
        ['flutter', 'precache'],
      ]);
    },
  );
}
