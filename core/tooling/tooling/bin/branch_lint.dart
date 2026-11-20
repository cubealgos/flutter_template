import 'dart:io';

import 'package:tooling/src/branch_lint_result.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';

/// Argument count of `--branch <name>`.
const int _branchArgCount = 2;

/// `branch_lint`: lists every local and remote branch and fails (exit 1)
/// if any doesn't conform to the six-family naming convention, or (exit
/// [gitFailureExitCode]) if the underlying `git for-each-ref` call itself
/// fails.
///
/// Usage: `fvm dart run tooling:branch_lint [--branch <name>]`
///
/// With `--branch <name>`, lints only that one name (same rule) and reads no
/// git refs at all — CI uses this because its persistent workspace keeps
/// refs from earlier checkouts. Exit [usageExitCode] on a malformed
/// command line.
Future<void> main(List<String> args) async {
  final String? branch;
  if (args.isEmpty) {
    branch = null;
  } else if (args.first == '--branch' &&
      args.length == _branchArgCount &&
      args[1] != '') {
    branch = args[1];
  } else {
    stderr.writeln('Usage: branch_lint [--branch <name>]');
    exit(usageExitCode);
  }

  final BranchLintResult result;
  try {
    result = branch != null
        ? lintBranchName(branch)
        : await lintBranches(
            const SystemProcessRunner(),
            repoRoot: Directory.current.path,
          );
  } on CommandFailure catch (e) {
    stderr.writeln(e.message);
    exit(e.exitCode);
  }

  if (result.isClean) {
    stdout.writeln(
      'branch_lint: all branches conform to the naming convention.',
    );
    exit(0);
  }

  stderr
    ..writeln(
      'branch_lint found ${result.offenders.length} non-conforming branch(es):',
    )
    ..writeln();
  for (final offender in result.offenders) {
    stderr.writeln('  $offender');
  }
  exit(1);
}
