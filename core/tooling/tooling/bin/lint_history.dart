import 'dart:io';

import 'package:tooling/src/commit_rule.dart';

/// Exit code used when `git log` itself fails (as opposed to finding
/// offending commits, which exits with [_offendersFoundExitCode]).
const int _gitFailureExitCode = 2;

/// Exit code used when one or more commit subjects fail
/// [validateCommitSubject].
const int _offendersFoundExitCode = 1;

/// How many characters of a commit SHA to show in offender output — enough
/// to be unambiguous in a small repo without cluttering the message.
const int _shaDisplayLength = 12;

/// Checks every commit subject on the current branch against
/// [validateCommitSubject], except SHAs listed in `tool/commit-baseline.txt`.
///
/// Usage:
///   dart run tooling:lint_history [--repo <path>] [--baseline <path>]
///     [<git log range>]
///
/// `--repo` is the git repository to check (defaults to the current
/// directory). With no range argument, checks `git log --format=%H%x09%s`
/// for the current `HEAD` (i.e. every commit reachable from `HEAD`). Pass a
/// git revision range (e.g. `main..HEAD`) to narrow the check.
Future<void> main(List<String> args) async {
  final parsedArgs = _parseArgs(args);
  final baseline = _readBaseline(parsedArgs.baselinePath);

  final logArgs = <String>[
    'log',
    '--format=%H%x09%s',
    ...parsedArgs.positional,
  ];
  final result = await Process.run(
    'git',
    logArgs,
    workingDirectory: parsedArgs.repoPath,
  );
  if (result.exitCode != 0) {
    stderr.writeln('git log failed:\n${result.stderr}');
    exit(_gitFailureExitCode);
  }

  final output = (result.stdout as String).trim();
  final lines = output.isEmpty ? <String>[] : output.split('\n');
  final offenders = _findOffenders(lines, baseline);

  if (offenders.isNotEmpty) {
    stderr
      ..writeln('lint_history found ${offenders.length} offending commit(s):')
      ..writeln();
    for (final offender in offenders) {
      stderr.writeln('  $offender');
    }
    exit(_offendersFoundExitCode);
  }

  stdout.writeln(
    'lint_history: ${lines.length} commit(s) checked, '
    '${baseline.length} baseline exemption(s), no offenders.',
  );
  exit(0);
}

/// The parsed command-line arguments: `--baseline`/`--repo` options plus
/// whatever positional arguments (a git revision range) remain.
///
/// A record, not a class — this is private, throwaway shape with no
/// behavior, and `prefer_match_file_name` would otherwise want it (the only
/// class in this file) to be named after the file.
typedef _ParsedArgs = ({
  /// Path to the baseline file (`--baseline`, defaults to
  /// `tool/commit-baseline.txt`).
  String baselinePath,

  /// The git repository to check (`--repo`, defaults to the current
  /// directory).
  String repoPath,

  /// Everything left over after consuming `--baseline`/`--repo` — passed
  /// through to `git log` as a revision range.
  List<String> positional,
});

/// Parses [args] into a [_ParsedArgs], consuming `--baseline <path>` and
/// `--repo <path>` and leaving everything else as its `positional` field.
_ParsedArgs _parseArgs(List<String> args) {
  var baselinePath = 'tool/commit-baseline.txt';
  var repoPath = Directory.current.path;
  final positional = <String>[];

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--baseline' && i + 1 < args.length) {
      baselinePath = args[++i];
    } else if (args[i] == '--repo' && i + 1 < args.length) {
      repoPath = args[++i];
    } else {
      positional.add(args[i]);
    }
  }

  return (
    baselinePath: baselinePath,
    repoPath: repoPath,
    positional: positional,
  );
}

/// Checks every `<sha>\t<subject>` line in [lines] against
/// [validateCommitSubject], skipping any SHA in [baseline], and returns a
/// human-readable description of each offender.
List<String> _findOffenders(List<String> lines, Set<String> baseline) {
  final offenders = <String>[];

  for (final line in lines) {
    final tabIndex = line.indexOf('\t');
    if (tabIndex < 0) continue;
    final sha = line.substring(0, tabIndex);
    final subject = line.substring(tabIndex + 1);

    if (baseline.contains(sha)) continue;

    final error = validateCommitSubject(subject);
    if (error != null) {
      offenders.add(
        '${sha.substring(0, _shaDisplayLength)}  $subject\n    $error',
      );
    }
  }

  return offenders;
}

/// Reads the baseline SHA list at [path] (one SHA per line, `#`-prefixed
/// lines and blank lines ignored), or an empty set if it doesn't exist.
Set<String> _readBaseline(String path) {
  final file = File(path);
  if (!file.existsSync()) return <String>{};

  final shas = <String>{};
  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    shas.add(line);
  }

  return shas;
}
