import 'dart:io';

import 'package:path/path.dart' as p;

/// The Flutter version [createGitFixture] writes to `.fvmrc`, matching
/// what `branch_new`'s `fvm use` step is expected to pin a new worktree to.
const String fixtureFlutterVersion = '3.47.5';

/// A disposable local git setup for command tests: a bare "origin" repo
/// shaped `<owner>/<repo>.git` (so `parseGitRemoteUrl`'s local-path
/// fallback derives sensible owner/repo values) with `development` and
/// `production` branches, plus a full clone at [mainCheckout] sitting on
/// `development` — the "main checkout" a workflow-tooling command expects.
class GitFixture {
  const GitFixture({
    required this.tempDir,
    required this.originPath,
    required this.mainCheckout,
    required this.seedCheckout,
  });

  /// The fixture's root — delete this to clean up everything.
  final Directory tempDir;

  /// The bare origin repo's filesystem path.
  final String originPath;

  /// A full clone of [originPath], checked out on `development`.
  final Directory mainCheckout;

  /// A second full clone of [originPath], used to simulate a forge-side
  /// merge (creating a real merge commit and pushing it) without disturbing
  /// [mainCheckout]'s own state before a command under test runs.
  final Directory seedCheckout;

  /// Deletes [tempDir] and everything under it.
  void dispose() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  }
}

/// Builds a [GitFixture] under a fresh temp directory.
Future<GitFixture> createGitFixture({
  String owner = 'example-org',
  String repo = 'my_app',
}) async {
  final tempDir = Directory.systemTemp.createTempSync('tooling_git_fixture_');
  final originDir = Directory(p.join(tempDir.path, owner, '$repo.git'))
    ..createSync(recursive: true);
  await runGit(['init', '--bare', '-q'], originDir.path);

  final seedDir = Directory(p.join(tempDir.path, 'seed'))..createSync();
  await runGit(['init', '-q', '-b', 'development'], seedDir.path);
  File(p.join(seedDir.path, 'README.md')).writeAsStringSync('seed\n');
  File(p.join(seedDir.path, '.fvmrc'))
      .writeAsStringSync('{\n  "flutter": "$fixtureFlutterVersion"\n}\n');
  // Matches the real repo's own root `.gitignore` (`.fvm/`) — without it,
  // a fake `fvm use` that stubs `.fvm/flutter_sdk/bin/dart` into a cloned
  // fixture would show up as an untracked file, which `gen_fresh_check`'s
  // own `git status --porcelain` clean-tree check would then (wrongly)
  // flag as the fresh clone being dirty.
  File(p.join(seedDir.path, '.gitignore')).writeAsStringSync('.fvm/\n');
  await runGit(['add', 'README.md', '.fvmrc', '.gitignore'], seedDir.path);
  await commitInGit(seedDir.path, 'chore(repo): seed fixture (#0)');
  await runGit(['remote', 'add', 'origin', originDir.path], seedDir.path);
  await runGit(['push', '-q', 'origin', 'development'], seedDir.path);
  await runGit(['checkout', '-q', '-b', 'production'], seedDir.path);
  await runGit(['push', '-q', 'origin', 'production'], seedDir.path);
  await runGit(['checkout', '-q', 'development'], seedDir.path);

  // Real remotes have a HEAD symref (`origin/HEAD -> origin/development`),
  // and git abbreviates ITS short name to plain "origin", not "origin/HEAD"
  // — a real bug branch_lint had to account for. Set it explicitly so the
  // fixture reproduces that instead of leaving origin's HEAD unborn.
  await runGit([
    'symbolic-ref',
    'HEAD',
    'refs/heads/development',
  ], originDir.path);

  final mainCheckout = Directory(p.join(tempDir.path, 'main'));
  await runGit([
    'clone',
    '-q',
    originDir.path,
    mainCheckout.path,
  ], tempDir.path);
  await runGit(['checkout', '-q', 'development'], mainCheckout.path);

  return GitFixture(
    tempDir: tempDir,
    originPath: originDir.path,
    mainCheckout: mainCheckout,
    seedCheckout: seedDir,
  );
}

/// Runs `git <args>` in [cwd], throwing with full output if it fails.
Future<ProcessResult> runGit(List<String> args, String cwd) async {
  final result = await Process.run('git', args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.join(' ')} failed in $cwd:\n'
      '${result.stdout}\n${result.stderr}',
    );
  }

  return result;
}

/// Commits staged changes in [cwd] with a fixed, deterministic identity.
Future<void> commitInGit(String cwd, String subject) => runGit([
  '-c',
  'user.name=Test',
  '-c',
  'user.email=test@example.com',
  'commit',
  '-m',
  subject,
], cwd);

/// The full SHA of `HEAD` in [cwd].
Future<String> revParseHead(String cwd) async {
  final result = await runGit(['rev-parse', 'HEAD'], cwd);

  return (result.stdout as String).trim();
}
