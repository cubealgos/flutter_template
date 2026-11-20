import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';

/// Refuses (via [CommandFailure]) unless [repoRoot] is the *main* checkout
/// of its git repository, never a linked worktree.
///
/// A linked worktree's `git rev-parse --git-dir` points at a private
/// subdirectory of the main checkout's `.git` (`.git/worktrees/<name>`),
/// while its `--git-common-dir` always points at the shared main `.git` —
/// the two differ only inside a worktree, never in the main checkout.
Future<void> ensureMainCheckout(ProcessRunner runner, String repoRoot) async {
  final gitDir = await _resolveGitPath(runner, repoRoot, '--git-dir');
  final commonDir = await _resolveGitPath(runner, repoRoot, '--git-common-dir');
  if (gitDir != commonDir) {
    throw CommandFailure(
      'This command must be run from the main checkout, not a linked '
      'worktree (git-dir "$gitDir" != git-common-dir "$commonDir").',
    );
  }
}

Future<String> _resolveGitPath(
  ProcessRunner runner,
  String repoRoot,
  String flag,
) async {
  final result = await runner.run('git', [
    'rev-parse',
    flag,
  ], workingDirectory: repoRoot);
  if (result.exitCode != 0) {
    throw CommandFailure('git rev-parse $flag failed: ${result.stderr}');
  }
  final raw = (result.stdout as String).trim();

  return p.normalize(p.isAbsolute(raw) ? raw : p.join(repoRoot, raw));
}
