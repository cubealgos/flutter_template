import 'dart:io';

import 'package:path/path.dart' as p;

/// The result of [verifyRelativeWorktreeLink]: whether the worktree's
/// on-disk link back to the main checkout is genuinely relative, and if
/// not, why.
class WorktreeLinkCheck {
  /// Creates a check result.
  const WorktreeLinkCheck({required this.isRelative, this.reason});

  /// True if both halves of the link are relative paths.
  final bool isRelative;

  /// A human-readable reason [isRelative] is false. Null when it's true.
  final String? reason;
}

/// Verifies that `git worktree add --relative-paths` actually produced a
/// relative link for the worktree named [worktreeName] under
/// `<repoRoot>/.worktrees/<worktreeName>`, rather than trusting the flag.
///
/// Checks both halves of the link: the worktree's own `.git` file (its
/// `gitdir:` pointer back to `<repoRoot>/.git/worktrees/<worktreeName>`)
/// and the main checkout's matching `.git/worktrees/<worktreeName>/gitdir`
/// file (its pointer forward to the worktree's `.git`). Either half can be
/// absolute even when the other is relative, so both are checked.
WorktreeLinkCheck verifyRelativeWorktreeLink({
  required String repoRoot,
  required String worktreeName,
}) {
  final worktreeGitFile = File(
    p.join(repoRoot, '.worktrees', worktreeName, '.git'),
  );
  final mainGitdirFile = File(
    p.join(repoRoot, '.git', 'worktrees', worktreeName, 'gitdir'),
  );

  if (!worktreeGitFile.existsSync()) {
    return WorktreeLinkCheck(
      isRelative: false,
      reason: '${worktreeGitFile.path} does not exist.',
    );
  }
  if (!mainGitdirFile.existsSync()) {
    return WorktreeLinkCheck(
      isRelative: false,
      reason: '${mainGitdirFile.path} does not exist.',
    );
  }

  final worktreeSide = _extractGitdirPointer(worktreeGitFile);
  if (worktreeSide == null || p.isAbsolute(worktreeSide)) {
    return WorktreeLinkCheck(
      isRelative: false,
      reason:
          '${worktreeGitFile.path} points at an absolute path: '
          '"${worktreeSide ?? worktreeGitFile.readAsStringSync().trim()}".',
    );
  }

  final mainSide = mainGitdirFile.readAsStringSync().trim();
  if (p.isAbsolute(mainSide)) {
    return WorktreeLinkCheck(
      isRelative: false,
      reason:
          '${mainGitdirFile.path} points at an absolute path: '
          '"$mainSide".',
    );
  }

  return const WorktreeLinkCheck(isRelative: true);
}

final RegExp _gitdirLinePattern = RegExp(r'^gitdir:\s*(.+)$');

String? _extractGitdirPointer(File worktreeGitFile) {
  final content = worktreeGitFile.readAsStringSync().trim();
  final match = _gitdirLinePattern.firstMatch(content);

  return match?.group(1)?.trim();
}
