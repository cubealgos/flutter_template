import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/main_checkout.dart';
import 'package:tooling/src/process_runner.dart';

import 'support/git_fixture.dart';

void main() {
  // Assigned in setUp/read in tests/cleaned in tearDown — the standard
  // package:test fixture-per-test pattern; there's no meaningful non-null
  // default to construct it with instead.
  // ignore: solid_lints/avoid_late_keyword
  late Directory repo;
  const runner = SystemProcessRunner();

  setUp(() {
    repo = Directory.systemTemp.createTempSync('tooling_main_checkout_test_');
  });

  tearDown(() {
    if (repo.existsSync()) repo.deleteSync(recursive: true);
  });

  test('accepts the main checkout', () async {
    await runGit(['init', '-q', '-b', 'development'], repo.path);
    File(p.join(repo.path, 'f.txt')).writeAsStringSync('x\n');
    await runGit(['add', 'f.txt'], repo.path);
    await commitInGit(repo.path, 'chore(repo): initialize (#1)');

    await expectLater(ensureMainCheckout(runner, repo.path), completes);
  });

  test('refuses a linked worktree', () async {
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

    final worktreePath = p.join(repo.path, '.worktrees', '1');
    await expectLater(
      ensureMainCheckout(runner, worktreePath),
      throwsA(isA<CommandFailure>()),
    );
  });
}
