import 'dart:io';

import 'package:path/path.dart' as p;

/// Walks up from [start] to find the workspace root: the nearest ancestor
/// directory whose `pubspec.yaml` has a top-level `workspace:` key.
///
/// Mirrors `tooling`'s own `findRepoRoot`
/// (`core/tooling/tooling/lib/src/map_generator.dart`) — duplicated rather
/// than depended on, to keep `backend`'s own dependency surface (and
/// therefore what a deployed function bundle could end up vendoring) from
/// growing for a ten-line helper.
///
/// Throws a [StateError] if no such ancestor exists.
Directory findRepoRoot(Directory start) {
  var dir = start.absolute;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    final hasWorkspaceKey =
        pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('workspace:');
    if (hasWorkspaceKey) return dir;

    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find the workspace root above ${dir.path}.');
    }
    dir = parent;
  }
}

/// The directory every worktree of this clone shares for dev-backend
/// secrets — the *main* checkout's own `backend/` directory. Its
/// `appwrite/tool/.env.local` holds the Appwrite Cloud project's endpoint,
/// project ID and API key.
///
/// [findRepoRoot] finds the nearest ancestor with a workspace `pubspec.yaml`
/// — inside a linked worktree (`.worktrees/<N>/`, see root `CLAUDE.md`),
/// that is the worktree's own checked-out copy, which is exactly the
/// problem: `backend/appwrite/tool/.env.local` is a gitignored file that
/// lives nowhere but that worktree's own working tree, so
/// `git worktree remove` deletes it along with it.
///
/// `git rev-parse --git-common-dir`, run in [start], resolves the *shared*
/// git directory instead: identical for the main checkout and every one of
/// its linked worktrees (unlike `--git-dir`, which is worktree-private —
/// see `core/tooling/tooling/lib/src/main_checkout.dart`'s own use of the same
/// distinction). Its parent is therefore always the main checkout's own
/// root, never a worktree's, because this repo's main checkout keeps `.git`
/// directly under its root (never nested elsewhere).
///
/// Returns null if [start] isn't inside a git repository at all (`git`
/// missing, or the command fails) rather than throwing, so callers with
/// their own fallback — `BackendEnv.load`'s `dotEnvFile` candidates among
/// them — can treat "no git repo" the same as "file not found".
///
/// Uses [Process.runSync]: `BackendEnv.load` is a synchronous factory
/// (kept that way so every existing caller — `bin/provision.dart`,
/// `bin/deploy.dart`, this package's own integration tests — stays
/// synchronous too), and this is the one call in its discovery chain that
/// would otherwise need to shell out.
Directory? findSharedBackendDir(Directory start) {
  final ProcessResult result;
  try {
    result = Process.runSync('git', [
      'rev-parse',
      '--git-common-dir',
    ], workingDirectory: start.absolute.path);
  } on ProcessException {
    return null;
  }
  if (result.exitCode != 0) return null;

  final raw = (result.stdout as String).trim();
  final commonDir = p.normalize(
    p.isAbsolute(raw) ? raw : p.join(start.absolute.path, raw),
  );

  return Directory(p.join(Directory(commonDir).parent.path, 'backend'));
}
