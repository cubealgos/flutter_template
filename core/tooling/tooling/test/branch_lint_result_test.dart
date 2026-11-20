import 'dart:io';

import 'package:test/test.dart';
import 'package:tooling/src/branch_lint_result.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';

import 'support/git_fixture.dart';

void main() {
  test(
    'flags non-conforming local and remote branches, ignores the rest',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final main = fixture.mainCheckout.path;

      // Conforming local branches: exempt long-lived branches, an ordinary
      // family branch, and the release/<pkg>-v<semver> alternate shape.
      await runGit(['branch', 'feature/11-workflow-tooling'], main);
      await runGit(['branch', 'release/tooling-v1.2.3'], main);

      // Non-conforming local branches.
      await runGit(['branch', 'feat/11-wrong-family'], main);
      await runGit(['branch', 'feature/11_bad_slug'], main);

      // A conforming and a non-conforming branch that exist only on the
      // remote (never checked out locally) — branch_lint must still see them.
      await runGit([
        'push',
        '-q',
        'origin',
        'HEAD:refs/heads/chore/12-remote-only',
      ], main);
      await runGit([
        'push',
        '-q',
        'origin',
        'HEAD:refs/heads/totally-unnamed',
      ], main);

      final result = await lintBranches(
        const SystemProcessRunner(),
        repoRoot: main,
      );

      expect(
        result.offenders,
        containsAll(<String>[
          'feat/11-wrong-family',
          'feature/11_bad_slug',
          'totally-unnamed',
        ]),
      );
      expect(result.offenders, isNot(contains('development')));
      expect(result.offenders, isNot(contains('production')));
      expect(result.offenders, isNot(contains('feature/11-workflow-tooling')));
      expect(result.offenders, isNot(contains('release/tooling-v1.2.3')));
      expect(result.offenders, isNot(contains('chore/12-remote-only')));
      expect(
        result.offenders,
        isNot(contains('origin')),
        reason:
            'the origin/HEAD symref abbreviates to "origin", not '
            '"origin/HEAD" — must be excluded by %(symref), not a /HEAD '
            'suffix check',
      );
      expect(result.isClean, isFalse);
    },
  );

  test('isClean when every branch conforms', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);

    final result = await lintBranches(
      const SystemProcessRunner(),
      repoRoot: fixture.mainCheckout.path,
    );

    expect(result.isClean, isTrue);
    expect(result.offenders, isEmpty);
  });

  test(
    'throws a CommandFailure with gitFailureExitCode when repoRoot is not '
    'a git repository — never a bare, uncaught StateError, so '
    'bin/branch_lint.dart can map it to a clean, deliberate exit code '
    'instead of relying on the VM default for an uncaught exception',
    () async {
      final notAGitRepo = Directory.systemTemp.createTempSync(
        'tooling_branch_lint_not_a_repo_',
      );
      addTearDown(() => notAGitRepo.deleteSync(recursive: true));

      await expectLater(
        lintBranches(const SystemProcessRunner(), repoRoot: notAGitRepo.path),
        throwsA(
          isA<CommandFailure>()
              .having((e) => e.exitCode, 'exitCode', gitFailureExitCode)
              .having(
                (e) => e.message,
                'message',
                contains('git for-each-ref refs/heads/ failed'),
              ),
        ),
      );
    },
  );

  group('lintBranchName', () {
    test('is clean for conforming names', () {
      for (final name in [
        'development',
        'production',
        'chore/41-self-hosted-ci',
        'release/tooling-v1.2.3',
      ]) {
        expect(lintBranchName(name).isClean, isTrue, reason: name);
      }
    });

    test('reports a non-conforming name as the sole offender', () {
      final result = lintBranchName('42/merge');

      expect(result.isClean, isFalse);
      expect(result.offenders, ['42/merge']);
    });
  });
}
