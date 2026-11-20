import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/worktree_link_check.dart';

import 'support/git_fixture.dart';

void main() {
  // Assigned in setUp/read in tests/cleaned in tearDown — the standard
  // package:test fixture-per-test pattern; there's no meaningful non-null
  // default to construct it with instead.
  // ignore: solid_lints/avoid_late_keyword
  late Directory repo;

  setUp(() {
    repo = Directory.systemTemp.createTempSync('tooling_worktree_link_test_');
  });

  tearDown(() {
    if (repo.existsSync()) repo.deleteSync(recursive: true);
  });

  Future<void> initRepoWithWorktree() async {
    await runGit(['init', '-q', '-b', 'development'], repo.path);
    File(p.join(repo.path, 'f.txt')).writeAsStringSync('x\n');
    await runGit(['add', 'f.txt'], repo.path);
    await commitInGit(repo.path, 'chore(repo): initialize (#1)');
    await runGit([
      'worktree',
      'add',
      '--relative-paths',
      '-b',
      'feature/1-thing',
      '.worktrees/1',
    ], repo.path);
  }

  test('a real --relative-paths worktree link is relative', () async {
    await initRepoWithWorktree();

    final check = verifyRelativeWorktreeLink(
      repoRoot: repo.path,
      worktreeName: '1',
    );

    expect(check.isRelative, isTrue, reason: check.reason);
  });

  test('flags a worktree-side gitdir pointer that is absolute', () async {
    await initRepoWithWorktree();
    final worktreeGitFile = File(p.join(repo.path, '.worktrees', '1', '.git'));
    final absoluteTarget = p.join(repo.path, '.git', 'worktrees', '1');
    worktreeGitFile.writeAsStringSync('gitdir: $absoluteTarget\n');

    final check = verifyRelativeWorktreeLink(
      repoRoot: repo.path,
      worktreeName: '1',
    );

    expect(check.isRelative, isFalse);
    expect(check.reason, contains('absolute path'));
  });

  test('flags a main-side gitdir pointer that is absolute', () async {
    await initRepoWithWorktree();
    final mainGitdirFile = File(
      p.join(repo.path, '.git', 'worktrees', '1', 'gitdir'),
    );
    final absoluteTarget = p.join(repo.path, '.worktrees', '1', '.git');
    mainGitdirFile.writeAsStringSync('$absoluteTarget\n');

    final check = verifyRelativeWorktreeLink(
      repoRoot: repo.path,
      worktreeName: '1',
    );

    expect(check.isRelative, isFalse);
    expect(check.reason, contains('absolute path'));
  });

  test('flags a missing worktree .git file', () {
    final check = verifyRelativeWorktreeLink(
      repoRoot: repo.path,
      worktreeName: 'does-not-exist',
    );

    expect(check.isRelative, isFalse);
    expect(check.reason, contains('does not exist'));
  });
}
