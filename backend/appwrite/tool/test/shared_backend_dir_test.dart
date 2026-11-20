import 'dart:io';

import 'package:appwrite_tool/src/repo_root.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/git_test_helper.dart';

void main() {
  test("resolves to the main checkout's backend/, from both the main "
      "checkout and a linked worktree - never a worktree's own copy", () async {
    final tempDir = Directory.systemTemp.createTempSync(
      'shared_backend_dir_test',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final mainCheckout = Directory(p.join(tempDir.path, 'main'))..createSync();
    await runGit(['init', '-q', '-b', 'development'], mainCheckout.path);
    File(p.join(mainCheckout.path, 'README.md')).writeAsStringSync('seed\n');
    await commitInGit(mainCheckout.path, 'README.md', 'seed');
    // Exists for real so `resolveSymbolicLinksSync` below (needed to
    // compare paths reliably - see its own comment) has something to
    // resolve; a real main checkout always has this directory checked out.
    Directory(p.join(mainCheckout.path, 'backend')).createSync();

    final worktree = Directory(p.join(tempDir.path, 'wt24'));
    await runGit([
      'worktree',
      'add',
      '--relative-paths',
      '-q',
      worktree.path,
      '-b',
      'bugfix/24-test',
    ], mainCheckout.path);

    // `git rev-parse --git-common-dir` prints a bare relative `.git` when
    // run from inside the main checkout, but an absolute (and, on macOS,
    // symlink-resolved) path when run from a linked worktree - both
    // resolve to the same real directory, just spelled differently, so
    // both sides are canonicalized via `resolveSymbolicLinksSync` before
    // comparing rather than compared as raw strings. Nullable in, nullable
    // out (rather than asserting non-null with `!`): a null here just
    // fails the `expect` below with a clear mismatch instead of throwing.
    String? canonical(Directory? dir) => dir?.resolveSymbolicLinksSync();

    final expected = canonical(Directory(p.join(mainCheckout.path, 'backend')));

    expect(canonical(findSharedBackendDir(mainCheckout)), expected);
    expect(canonical(findSharedBackendDir(worktree)), expected);
  });

  test('returns null outside any git repository', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'shared_backend_dir_test_no_git',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    expect(findSharedBackendDir(tempDir), isNull);
  });
}
