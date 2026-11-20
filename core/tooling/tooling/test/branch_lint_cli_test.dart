@Tags(['cli'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/branch_lint_result.dart';
import 'package:tooling/src/command_failure.dart';

/// Exercises `bin/branch_lint.dart` as an actual subprocess. Complements
/// `branch_lint_result_test.dart` (which tests [lintBranches] in-process):
/// this file checks what `bin/branch_lint.dart` itself does with a thrown
/// `CommandFailure` — that it prints a clean message and calls `exit()`
/// with the matching code, rather than letting it escape as an uncaught
/// exception (which happens to also exit non-zero on this Dart version, but
/// with an unstable, undocumented code and a raw stack trace on stderr).
void main() {
  Future<ProcessResult> runBranchLint(
    String workingDirectory, [
    List<String> args = const [],
  ]) => Process.run('dart', [
    'run',
    p.join(Directory.current.path, 'bin', 'branch_lint.dart'),
    ...args,
  ], workingDirectory: workingDirectory);

  test('exits with the dedicated git-failure code and a clean message when '
      'run outside a git repository', () async {
    final notAGitRepo = Directory.systemTemp.createTempSync(
      'tooling_branch_lint_cli_not_a_repo_',
    );
    addTearDown(() => notAGitRepo.deleteSync(recursive: true));

    final result = await runBranchLint(notAGitRepo.path);

    expect(
      result.exitCode,
      gitFailureExitCode,
      reason: '${result.stdout}\n${result.stderr}',
    );
    expect(result.stderr, contains('git for-each-ref refs/heads/ failed'));
    expect(
      result.stderr,
      isNot(contains('Unhandled exception')),
      reason: 'a git failure is a clean refusal, not an uncaught crash',
    );
  });

  group('--branch', () {
    // A non-git directory: any git call would exit gitFailureExitCode, so
    // success proves no git process ran and no ref was read.
    Directory makeNotAGitRepo() {
      final dir = Directory.systemTemp.createTempSync(
        'tooling_branch_lint_cli_branch_',
      );
      addTearDown(() => dir.deleteSync(recursive: true));

      return dir;
    }

    test('exits 0 for a conforming name without running git', () async {
      final result = await runBranchLint(makeNotAGitRepo().path, [
        '--branch',
        'chore/41-self-hosted-ci',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });

    test('exits 1 and names a non-conforming branch', () async {
      final result = await runBranchLint(makeNotAGitRepo().path, [
        '--branch',
        '42/merge',
      ]);

      expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stderr, contains('found 1 non-conforming branch(es)'));
      expect(result.stderr, contains('42/merge'));
    });

    test('exits with the usage code when the name is missing', () async {
      final result = await runBranchLint(makeNotAGitRepo().path, ['--branch']);

      expect(result.exitCode, usageExitCode);
    });
  });
}
