import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/verification_suite.dart';

/// One `run()` invocation recorded by [_RecordingRunner].
typedef _RecordedCall = ({
  String executable,
  List<String> arguments,
  String? workingDirectory,
  Map<String, String>? environment,
});

/// A [ProcessRunner] fake that records every call and answers via a
/// caller-supplied [handler] keyed off the melos script name (the last
/// argument) — used to unit-test [runVerificationSuite] directly, without
/// the `gh`/`fvm` split `ScriptedProcessRunner` is built for.
//
// This file is named for the function under test, not for this private
// fake ProcessRunner (the only class declared here).
// ignore: solid_lints/prefer_match_file_name
class _RecordingRunner implements ProcessRunner {
  _RecordingRunner(this.handler);

  final ProcessResult Function(String script, int callNumberForScript) handler;
  final List<_RecordedCall> calls = <_RecordedCall>[];
  final Map<String, int> _callCounts = {};

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    calls.add((
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    ));
    final script = arguments.last;
    final callNumber = (_callCounts[script] ?? 0) + 1;
    _callCounts[script] = callNumber;

    return handler(script, callNumber);
  }
}

ProcessResult _pass() => ProcessResult(0, 0, '', '');
ProcessResult _fail({String stdout = 'check failed'}) =>
    ProcessResult(0, 1, stdout, '');

/// How many of [verificationMelosScripts] run before the suite stops, in
/// the "stops at the first failing check" test — the failing script is
/// `verificationMelosScripts[1]`, so exactly two checks run.
const int _scriptsRunBeforeStopping = 2;

/// How many `fvm` calls a once-retried check makes: the first attempt plus
/// exactly one retry.
const int _callsForARetriedCheck = 2;

/// How many fake output lines the tail-printing test generates — more than
/// [failureOutputTailLines] so the test can assert the tail actually
/// truncates.
const int _tailTestLineCount = 60;

void main() {
  final buffer = StringBuffer();
  void out(String m) => buffer.writeln(m);

  // Assigned in setUp/read in tests/cleaned in tearDown — repoRoot needs a
  // real, writable directory now that a failing check writes a log file
  // under `<repoRoot>/.dart_tool/tooling/`.
  // ignore: solid_lints/avoid_late_keyword
  late Directory repo;

  setUp(() {
    buffer.clear();
    repo = Directory.systemTemp.createTempSync('verification_suite_test_');
  });

  tearDown(() {
    if (repo.existsSync()) repo.deleteSync(recursive: true);
  });

  test('runs every script in order, in a repoRoot, with analytics '
      'suppressed', () async {
    final runner = _RecordingRunner((_, _) => _pass());

    final result = await runVerificationSuite(
      runner: runner,
      repoRoot: repo.path,
      out: out,
    );

    expect(result.passed, isTrue);
    expect(result.passedScripts, verificationMelosScripts);
    expect(runner.calls.map((c) => c.arguments.last), verificationMelosScripts);
    for (final call in runner.calls) {
      expect(call.executable, 'fvm');
      expect(call.arguments, [
        'dart',
        'run',
        'melos',
        'run',
        call.arguments.last,
      ]);
      expect(call.workingDirectory, repo.path);
      expect(call.environment, {'DASH__SUPPRESS_ANALYTICS': 'true'});
    }
  });

  test('stops at the first failing check without running later ones', () async {
    final failingScript = verificationMelosScripts[1];
    final runner = _RecordingRunner(
      (script, _) => script == failingScript ? _fail() : _pass(),
    );

    final result = await runVerificationSuite(
      runner: runner,
      repoRoot: repo.path,
      out: out,
    );

    expect(result.passed, isFalse);
    expect(result.firstFailure?.script, failingScript);
    expect(
      result.checks.map((c) => c.script),
      verificationMelosScripts.sublist(0, _scriptsRunBeforeStopping),
    );
    expect(runner.calls, hasLength(_scriptsRunBeforeStopping));
  });

  test("prints the tail of a failing check's output and writes the full "
      'output to a log file under .dart_tool/, printing its path', () async {
    final failingScript = verificationMelosScripts[1];
    final lines = List.generate(_tailTestLineCount, (i) => 'line $i');
    final fullOutput = lines.join('\n');
    final runner = _RecordingRunner(
      (script, _) =>
          script == failingScript ? _fail(stdout: fullOutput) : _pass(),
    );

    final result = await runVerificationSuite(
      runner: runner,
      repoRoot: repo.path,
      out: out,
    );

    expect(result.passed, isFalse);
    final printed = buffer.toString();
    // The tail (last 40 lines) must be printed...
    expect(printed, contains('line 59'));
    expect(printed, contains('line 20'));
    // ...but not the lines before it.
    expect(printed, isNot(contains('line 19\n')));

    final logPath = p.join(
      repo.path,
      '.dart_tool',
      'tooling',
      'verification-$failingScript.log',
    );
    expect(File(logPath).existsSync(), isTrue);
    expect(File(logPath).readAsStringSync(), contains(fullOutput));
    expect(printed, contains(logPath));
  });

  test('retries exactly once on the analysis-server-crashed signature, then '
      'passes', () async {
    final flakyScript = verificationMelosScripts[1];
    final runner = _RecordingRunner((script, callNumber) {
      if (script == flakyScript && callNumber == 1) {
        return _fail(
          stdout: 'Fatal error: analysis server crashed unexpectedly',
        );
      }

      return _pass();
    });

    final result = await runVerificationSuite(
      runner: runner,
      repoRoot: repo.path,
      out: out,
    );

    expect(result.passed, isTrue);
    final flakyCheck = result.checks.firstWhere((c) => c.script == flakyScript);
    expect(flakyCheck.retried, isTrue);
    expect(
      runner.calls.where((c) => c.arguments.last == flakyScript),
      hasLength(_callsForARetriedCheck),
    );
    expect(buffer.toString(), contains('retrying once'));
  });

  test('a retry that also fails is not retried again', () async {
    final flakyScript = verificationMelosScripts[1];
    final runner = _RecordingRunner((script, _) {
      if (script == flakyScript) {
        return _fail(
          stdout: 'Fatal error: analysis server crashed unexpectedly',
        );
      }

      return _pass();
    });

    final result = await runVerificationSuite(
      runner: runner,
      repoRoot: repo.path,
      out: out,
    );

    expect(result.passed, isFalse);
    expect(result.firstFailure?.script, flakyScript);
    expect(result.firstFailure?.retried, isTrue);
    expect(
      runner.calls.where((c) => c.arguments.last == flakyScript),
      hasLength(_callsForARetriedCheck),
      reason: 'must retry exactly once, not loop',
    );
  });

  test('an ordinary failure (no crash signature) is not retried', () async {
    final failingScript = verificationMelosScripts.first;
    final runner = _RecordingRunner(
      (script, _) => script == failingScript ? _fail() : _pass(),
    );

    final result = await runVerificationSuite(
      runner: runner,
      repoRoot: repo.path,
      out: out,
    );

    expect(result.passed, isFalse);
    expect(result.firstFailure?.retried, isFalse);
    expect(
      runner.calls.where((c) => c.arguments.last == failingScript),
      hasLength(1),
    );
  });
}
