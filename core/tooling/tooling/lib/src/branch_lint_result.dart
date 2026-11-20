import 'package:tooling/src/branch_families.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';

/// Exit code `branch_lint` uses when the underlying `git for-each-ref` call
/// itself fails — as opposed to finding non-conforming branches, which
/// [BranchLintResult.offenders] reports instead and `bin/branch_lint.dart`
/// maps to exit `1`. Matches `lint_history`'s `_gitFailureExitCode`
/// convention for the same underlying condition (the git plumbing command
/// failing, not the check it powers).
const int gitFailureExitCode = 2;

/// The result of [lintBranches]: every branch name that doesn't conform to
/// the six-family naming convention.
class BranchLintResult {
  /// Creates a result carrying [offenders] (sorted, deduplicated).
  const BranchLintResult({required this.offenders});

  /// Non-conforming branch names, sorted.
  final List<String> offenders;

  /// True if no offenders were found.
  bool get isClean => offenders.isEmpty;
}

/// Lists every local and remote branch under [repoRoot] and returns the
/// ones that don't conform to [branchNamePattern] or (for `release/*`)
/// [releasePackageVersionPattern] — [longLivedBranches] are exempt. Throws
/// [CommandFailure] (exit code [gitFailureExitCode]) if the underlying
/// `git for-each-ref` call itself fails, e.g. [repoRoot] is not a git
/// repository.
Future<BranchLintResult> lintBranches(
  ProcessRunner runner, {
  String repoRoot = '.',
}) async {
  final branches = <String>{
    ...await _localBranchNames(runner, repoRoot),
    ...await _remoteBranchNames(runner, repoRoot),
  };

  final offenders = branches.where(_isNonConforming).toList()..sort();

  return BranchLintResult(offenders: offenders);
}

/// Lints exactly the one [branch] name against the same rule
/// [lintBranches] applies, without running git or reading any ref — for CI,
/// where a persistent workspace accumulates refs from earlier checkouts
/// (e.g. `refs/remotes/pull/<n>/merge`) that are none of the pushed
/// branch's business.
BranchLintResult lintBranchName(String branch) =>
    BranchLintResult(offenders: _isNonConforming(branch) ? [branch] : const []);

bool _isNonConforming(String branch) {
  if (longLivedBranches.contains(branch)) return false;
  if (branchNamePattern.hasMatch(branch)) return false;
  if (releasePackageVersionPattern.hasMatch(branch)) return false;

  return true;
}

Future<List<String>> _localBranchNames(
  ProcessRunner runner,
  String repoRoot,
) async {
  final result = await runner.run('git', [
    'for-each-ref',
    '--format=%(refname:short)',
    'refs/heads/',
  ], workingDirectory: repoRoot);
  if (result.exitCode != 0) {
    throw CommandFailure(
      'git for-each-ref refs/heads/ failed: ${result.stderr}',
      exitCode: gitFailureExitCode,
    );
  }

  return _splitLines(result.stdout as String);
}

Future<List<String>> _remoteBranchNames(
  ProcessRunner runner,
  String repoRoot,
) async {
  // %(symref) is non-empty only for a symbolic ref such as `origin/HEAD`
  // (the remote's default-branch pointer) — git abbreviates its short name
  // to plain "origin", not "origin/HEAD", so filtering on a `/HEAD` suffix
  // would miss it. Filtering on %(symref) catches it regardless of how git
  // spells the short name.
  final result = await runner.run('git', [
    'for-each-ref',
    '--format=%(symref)%09%(refname:short)',
    'refs/remotes/',
  ], workingDirectory: repoRoot);
  if (result.exitCode != 0) {
    throw CommandFailure(
      'git for-each-ref refs/remotes/ failed: ${result.stderr}',
      exitCode: gitFailureExitCode,
    );
  }

  // Not `_splitLines`: its `.trim()` would strip a symbolic ref's leading
  // tab (an ordinary branch's %(symref) field is empty, so its line starts
  // with the `\t` separator), which then hides the tab this loop keys on.
  final branches = <String>[];
  for (final rawLine in (result.stdout as String).split('\n')) {
    final line = rawLine.endsWith('\r')
        ? rawLine.substring(0, rawLine.length - 1)
        : rawLine;
    final tabIndex = line.indexOf('\t');
    if (tabIndex < 0) continue;
    final isSymbolicRef = line.substring(0, tabIndex).isNotEmpty;
    if (isSymbolicRef) continue;
    branches.add(_stripRemoteName(line.substring(tabIndex + 1)));
  }

  return branches;
}

String _stripRemoteName(String ref) {
  final slash = ref.indexOf('/');

  return slash < 0 ? ref : ref.substring(slash + 1);
}

List<String> _splitLines(String text) => text
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();
