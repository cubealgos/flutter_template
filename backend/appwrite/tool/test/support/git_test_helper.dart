import 'dart:io';

/// Runs `git <args>` in [cwd], throwing with full output if it fails —
/// used by tests that need a real, disposable temp git repository (and,
/// where needed, a linked worktree) rather than faking `git` itself, since the
/// behavior under test (`findSharedBackendDir`) is exactly git's own
/// `--git-common-dir` resolution.
///
/// Structurally the same as `core/tooling/tooling/test/support/git_fixture.dart`'s
/// own `runGit` - duplicated rather than shared, since `tooling`'s test
/// support isn't part of its public `lib/` (nothing `backend` could depend
/// on even if it wanted to), same reasoning as `repo_root.dart`'s own
/// `findRepoRoot` duplicating `tooling`'s.
// ignore: solid_lints/avoid_duplicate_code
Future<void> runGit(List<String> args, String cwd) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed in $cwd:\n'
      '${result.stdout}\n${result.stderr}',
    );
  }
}

/// Commits [path] (relative to [cwd]) with a fixed, deterministic
/// identity and [subject] — [path] must already be staged or new.
Future<void> commitInGit(String cwd, String path, String subject) async {
  await runGit(['add', path], cwd);
  await runGit([
    '-c',
    'user.name=Test',
    '-c',
    'user.email=test@example.com',
    'commit',
    '-q',
    '-m',
    subject,
  ], cwd);
}
