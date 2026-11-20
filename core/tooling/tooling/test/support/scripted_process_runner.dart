import 'dart:convert';
import 'dart:io';

import 'package:tooling/src/process_runner.dart';

/// Answers one `gh` invocation given its full argument list (as passed to
/// the `gh` executable, e.g. `['pr', 'list', '--state', 'open', ...,
/// '--repo', 'owner/repo']`).
typedef GhHandler = ProcessResult Function(List<String> args);

/// Answers one `fvm` invocation (in practice, `finish`'s verification
/// suite: `fvm dart run melos run <script>`) given its full argument list.
typedef FvmHandler = ProcessResult Function(List<String> args);

/// A [ProcessRunner] that fakes every `gh` call via a caller-supplied
/// [ghHandler], optionally fakes every `fvm` call via [fvmHandler] (used
/// by `FinishCommand`'s verification suite), and delegates every other
/// executable (`git`, in practice) to the real OS process — so command
/// tests exercise real git against disposable temp repos while never
/// touching the network or spawning a real `fvm`/`melos` toolchain.
class ScriptedProcessRunner implements ProcessRunner {
  /// Creates a runner that answers `gh` with [ghHandler] and, if given,
  /// `fvm` with [fvmHandler]. A test that never drives `finish` past the
  /// point where it shells out to `fvm` can omit [fvmHandler].
  ScriptedProcessRunner(this.ghHandler, {this.fvmHandler});

  /// The fake handler for `gh` calls.
  final GhHandler ghHandler;

  /// The fake handler for `fvm` calls, if any.
  final FvmHandler? fvmHandler;

  /// Every `gh` argument list seen so far, in call order — lets a test
  /// assert on what was requested (e.g. that a label was added).
  final List<List<String>> ghCalls = <List<String>>[];

  /// Every `fvm` argument list seen so far, in call order — lets a test
  /// assert on which verification scripts were run, and in what order.
  final List<List<String>> fvmCalls = <List<String>>[];

  static const ProcessRunner _real = SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (executable == 'gh') {
      ghCalls.add(arguments);

      return ghHandler(arguments);
    }
    final fvm = fvmHandler;
    if (executable == 'fvm' && fvm != null) {
      fvmCalls.add(arguments);

      return fvm(arguments);
    }

    return await _real.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }
}

/// A successful [ProcessResult] whose stdout is [body] JSON-encoded.
ProcessResult jsonResult(dynamic body) =>
    ProcessResult(0, 0, jsonEncode(body), '');

/// A failed [ProcessResult] (non-zero exit) with [stdout]/[stderr] text —
/// used to simulate a `gh` error response (e.g. a merge conflict's "not
/// mergeable" text, or a secondary-rate-limit "HTTP 403").
ProcessResult failedResult({String stdout = '', String stderr = ''}) =>
    ProcessResult(0, 1, stdout, stderr);

/// The `gh` subcommand and action a full argument list starts with, e.g.
/// `"pr list"`, `"issue edit"` — everything `GitHubClient` (see
/// `lib/src/github_client.dart`) needs a test to route on, since `gh`
/// (unlike `tea api`) has no single endpoint/method shape.
String ghCommandOf(List<String> args) {
  if (args.isEmpty) return '';
  if (args.length == 1) return args.first;

  return '${args.first} ${args[1]}';
}

/// The value immediately following [flag] in a `gh` argument list, or
/// `null` if [flag] isn't present (e.g. `ghFlagValue(args, '--repo')` for
/// `['issue', 'view', '11', '--repo', 'o/r']` returns `'o/r'`).
String? ghFlagValue(List<String> args, String flag) {
  final index = args.indexOf(flag);

  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

/// The melos script name from a full `fvm` argument list built by
/// `runVerificationSuite` (`['dart', 'run', 'melos', 'run', <script>]`) —
/// always the last argument.
String melosScriptOf(List<String> args) => args.isEmpty ? '' : args.last;

/// A successful `fvm` [ProcessResult] for a passing verification check.
ProcessResult passingCheck() => ProcessResult(0, 0, '', '');

/// A failing `fvm` [ProcessResult] for a verification check, with [stdout]
/// text (default: a generic failure — pass a string containing
/// `analysisServerCrashSignature` to simulate a transient analysis-server
/// crash instead).
ProcessResult failingCheck({String stdout = 'check failed'}) =>
    ProcessResult(0, 1, stdout, '');
