import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/process_runner.dart';

/// The melos scripts `finish` runs, in order, against merged `development`
/// before closing the issue — one constant list shared by
/// [runVerificationSuite] and its tests so the set of checks is declared
/// exactly once. Each entry is a script name from root `pubspec.yaml`'s
/// `melos.scripts` block, run as `fvm dart run melos run <script>`.
const List<String> verificationMelosScripts = [
  'analyze',
  'test',
  'format',
  'map-check',
  'check-generated',
  'docs-check',
];

/// The environment variable `package:unified_analytics` (used by dartdev,
/// the Dart analysis server and the Flutter tool alike) reads to suppress
/// analytics for a single process tree, without touching the user's
/// on-disk `dart-flutter-telemetry.config` — see `DashEnvVar.suppressAnalytics`
/// in dart-lang/tools' `pkgs/unified_analytics/lib/src/enums.dart` and
/// `areAnalyticsSuppressed`/`getEnvironment` in that package's `utils.dart`
/// (also read directly by dart-lang/sdk's
/// `pkg/analysis_server/lib/src/utilities/env.dart`). Unlike
/// `dart --disable-analytics` (which rewrites that config file for every
/// future run), this only affects processes that inherit this variable,
/// for the duration of one run — set here to work around the Dart analysis
/// server twice crashing transiently while phoning home its own telemetry.
const String _suppressAnalyticsEnvVar = 'DASH__SUPPRESS_ANALYTICS';

/// The environment [runVerificationSuite] passes to every check's `fvm`
/// process (merged on top of the inherited parent environment — see
/// [ProcessRunner.run]'s `environment` parameter).
const Map<String, String> _checkEnvironment = {
  _suppressAnalyticsEnvVar: 'true',
};

/// The stdout/stderr substring identifying a transient Dart analysis
/// server crash (as opposed to a genuine check failure) — the only kind of
/// failure [runVerificationSuite] retries, and only once.
const String analysisServerCrashSignature =
    'analysis server crashed unexpectedly';

/// How many trailing lines of a failing check's output [runVerificationSuite]
/// prints inline — enough to usually catch a `dart test` run's failing-test
/// summary without dumping the whole (possibly huge) log to the console;
/// the full output always goes to the log file [_writeFailureLog] returns
/// the path to, regardless of this limit (`finish` used to print
/// only `Check "test" failed.`, hiding which test failed).
const int failureOutputTailLines = 40;

/// Where [_writeFailureLog] writes a failing check's full output, relative
/// to `repoRoot` — `.dart_tool/` since it's already gitignored workspace-
/// wide and never mistaken for a tracked file.
const String _failureLogDir = '.dart_tool/tooling';

/// One [verificationMelosScripts] entry's outcome.
//
// This file is named for what it does (`runVerificationSuite`), not for
// this result class — the file's first declared type.
// ignore: solid_lints/prefer_match_file_name
class VerificationCheckResult {
  /// Creates a check result.
  const VerificationCheckResult({
    required this.script,
    required this.passed,
    required this.output,
    this.retried = false,
  });

  /// The melos script name (e.g. `analyze`).
  final String script;

  /// Whether the check's process exited 0.
  final bool passed;

  /// The check's combined stdout and stderr.
  final String output;

  /// Whether this result came from a retry after an analysis-server-crash
  /// signature on the first attempt.
  final bool retried;
}

/// The outcome of running every [verificationMelosScripts] entry, stopping
/// at the first failure.
class VerificationSuiteResult {
  /// Creates a suite result from the checks actually run.
  const VerificationSuiteResult({required this.checks});

  /// Every check run, in order (stops at the first failure — later scripts
  /// are never attempted once an earlier one fails).
  final List<VerificationCheckResult> checks;

  /// Whether every check in [checks] passed.
  bool get passed => checks.every((check) => check.passed);

  /// The names of every check that ran and passed, in order.
  List<String> get passedScripts => checks
      .where((check) => check.passed)
      .map((check) => check.script)
      .toList();

  /// The first (and only, since the suite stops there) failing check, or
  /// `null` if [passed].
  VerificationCheckResult? get firstFailure {
    for (final check in checks) {
      if (!check.passed) return check;
    }

    return null;
  }
}

/// Runs every script in [verificationMelosScripts] against [repoRoot] via
/// `fvm dart run melos run <script>`, in order, stopping at the first
/// failing check — later checks are meaningless once one has already
/// failed. A check whose combined output contains
/// [analysisServerCrashSignature] is retried exactly once before being
/// counted as a failure; every other failure is not retried. [out]
/// receives one progress line per check.
Future<VerificationSuiteResult> runVerificationSuite({
  required ProcessRunner runner,
  required String repoRoot,
  required void Function(String) out,
}) async {
  final checks = <VerificationCheckResult>[];
  for (final script in verificationMelosScripts) {
    out('Running verification check "$script" (analytics suppressed)...');
    var result = await _runCheck(runner, repoRoot, script);
    if (!result.passed &&
        result.output.contains(analysisServerCrashSignature)) {
      out(
        'Check "$script" hit the analysis-server-crashed signature — '
        'retrying once.',
      );
      result = await _runCheck(runner, repoRoot, script, retried: true);
    }
    checks.add(result);
    if (!result.passed) {
      final logPath = _writeFailureLog(repoRoot, result);
      out('Check "$script" failed. Last $failureOutputTailLines line(s):');
      out(_tail(result.output, failureOutputTailLines));
      out('Full output: $logPath');
      break;
    }
    out('Check "$script" passed.');
  }

  return VerificationSuiteResult(checks: checks);
}

/// The last [maxLines] non-empty-trimmed lines of [output], joined back
/// with newlines (or the whole thing if it has fewer). Trailing blank
/// lines are dropped first so the tail isn't mostly whitespace.
String _tail(String output, int maxLines) {
  final lines = output.split('\n');
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  if (lines.length <= maxLines) return lines.join('\n');

  return lines.sublist(lines.length - maxLines).join('\n');
}

/// Writes [result]'s full combined output to a log file under
/// `repoRoot/.dart_tool/tooling/` and returns its path, so the console
/// only shows the tail ([_tail]) while the whole thing stays available —
/// overwrites any previous failure log for the same script, since only
/// the latest run's failure ever matters.
String _writeFailureLog(String repoRoot, VerificationCheckResult result) {
  final dir = Directory(p.join(repoRoot, _failureLogDir))
    ..createSync(recursive: true);
  final file = File(p.join(dir.path, 'verification-${result.script}.log'))
    ..writeAsStringSync(result.output);

  return file.path;
}

Future<VerificationCheckResult> _runCheck(
  ProcessRunner runner,
  String repoRoot,
  String script, {
  bool retried = false,
}) async {
  final result = await runner.run(
    'fvm',
    ['dart', 'run', 'melos', 'run', script],
    workingDirectory: repoRoot,
    environment: _checkEnvironment,
  );

  return VerificationCheckResult(
    script: script,
    passed: result.exitCode == 0,
    output: '${result.stdout}\n${result.stderr}',
    retried: retried,
  );
}
