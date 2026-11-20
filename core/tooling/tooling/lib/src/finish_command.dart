import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/acceptance_criteria.dart';
import 'package:tooling/src/branch_families.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/git_remote_info.dart';
import 'package:tooling/src/github_client.dart';
import 'package:tooling/src/main_checkout.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/verification_suite.dart';

/// The number of positional arguments `finish` takes: `<N>`.
const int _expectedArgCount = 1;

/// A branch ref's capture-group index for the issue number, in the
/// `^(family)/(\d+)-` pattern built from [branchFamilies].
const int _issueNumberGroup = 2;

/// The GitHub label name carried while a PR is under review.
const String _reviewLabel = 'status/review';

/// The GitHub label name carried while an issue is actively being worked.
const String _inProgressLabel = 'status/in-progress';

/// GitHub's `mergeable` value meaning the PR can be merged cleanly (the
/// other values are `CONFLICTING` and `UNKNOWN`, the latter while GitHub
/// is still computing it).
const String _mergeableState = 'MERGEABLE';

/// `finish <N>`: merges the open PR for issue `<N>`, verifies the merge
/// really landed (never trusting the API alone), removes the worktree,
/// fast-forwards the main checkout, runs [verificationMelosScripts] against
/// merged `development` and only then closes the issue explicitly. See
/// `CLAUDE.md` for the workflow this implements. A failing check leaves the
/// issue open and re-labels it `status/in-progress` instead of closing —
/// shared history is never rewritten, so recovery is a `bugfix/*`
/// forward-fix or a revert, not a rebase.
class FinishCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; tests
  /// override them (and [timing]) to capture output and avoid real delays.
  FinishCommand({
    required this.runner,
    this.timing = const FinishTiming(),
    this.out = _defaultOut,
    this.err = _defaultErr,
  });

  /// The process runner `git`/`gh` are invoked through.
  final ProcessRunner runner;

  /// Polling/wait durations — overridden to zero in tests.
  final FinishTiming timing;

  /// Sink for normal progress messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);

  /// Runs the command against the repository rooted at [repoRoot] (the
  /// main checkout — verified, not assumed). Returns the process exit code.
  Future<int> run(List<String> args, {required String repoRoot}) =>
      runCatchingFailures(() => _run(args, repoRoot), err);

  Future<void> _run(List<String> args, String repoRoot) async {
    final issueNumber = _parseArgs(args);
    await ensureMainCheckout(runner, repoRoot);
    final github = await _buildGitHubClient(repoRoot);

    final pr = await _findOpenPr(github, issueNumber);
    if (pr == null) {
      await _resumeFromMergedPr(repoRoot, github, issueNumber);

      return;
    }
    out(
      'Found open PR #${pr.index} (${pr.headRef} -> ${pr.base}) for issue '
      '#$issueNumber.',
    );

    await _refuseIfCriteriaUnchecked(github, issueNumber);
    await _waitUntilMergeable(github, pr);

    final mergeCommitSha = await _mergeAndVerify(repoRoot, github, pr);
    out(
      'Merged PR #${pr.index} ($mergeCommitSha) — verified origin/${pr.base} '
      'moved and contains ${pr.headSha}.',
    );

    await _removeWorktree(repoRoot, pr.headRef);
    await _fastForwardMainCheckout(repoRoot, pr.base, mergeCommitSha);
    await _verifyThenCloseOrRelabel(
      github,
      _MergeOutcome(
        issueNumber: issueNumber,
        mergeCommitSha: mergeCommitSha,
        base: pr.base,
        repoRoot: repoRoot,
      ),
    );
  }

  /// The resume path: reached when [_findOpenPr] finds nothing.
  /// If a merged PR still matches issue [issueNumber]'s branch pattern —
  /// meaning a prior `finish` run already merged it, most likely then
  /// failing at post-merge verification (relabelling the issue
  /// `status/in-progress` instead of closing it, per
  /// [_verifyThenCloseOrRelabel]) — this skips straight to re-running the
  /// verification suite against current [_MergeOutcome.base], never
  /// re-merging. Throws the same "no open PR" [CommandFailure] as before
  /// when there's truly no PR (open or merged) at all, or when the issue
  /// is already closed (nothing left to resume).
  Future<void> _resumeFromMergedPr(
    String repoRoot,
    GitHubClient github,
    int issueNumber,
  ) async {
    final merged = await _findMergedPr(github, issueNumber);
    if (merged == null) throw _noOpenPrFailure(issueNumber);

    final issue = await github.getIssue(issueNumber);
    if (issue['state'] == 'CLOSED') throw _noOpenPrFailure(issueNumber);

    out(
      'No open PR for issue #$issueNumber, but PR #${merged.index} '
      '(${merged.headRef}) is already merged into ${merged.base} as '
      '${merged.mergeCommitSha} — resuming: skipping the merge and '
      're-running the verification suite against current ${merged.base}.',
    );

    final currentSha = await _fetchAndFastForward(repoRoot, merged.base);
    await _verifyThenCloseOrRelabel(
      github,
      _MergeOutcome(
        issueNumber: issueNumber,
        mergeCommitSha: currentSha,
        base: merged.base,
        repoRoot: repoRoot,
      ),
    );
  }

  CommandFailure _noOpenPrFailure(int issueNumber) => CommandFailure(
    'No open PR found for issue #$issueNumber (looked for a head '
    'branch matching <family>/$issueNumber-<slug>).',
  );

  int _parseArgs(List<String> args) {
    if (args.length != _expectedArgCount) {
      throw CommandFailure('Usage: finish <N>', exitCode: usageExitCode);
    }
    final number = args.first;
    if (!RegExp(r'^\d+$').hasMatch(number)) {
      throw CommandFailure(
        'Issue number must be a positive integer, got "$number".',
      );
    }

    return int.parse(number);
  }

  Future<GitHubClient> _buildGitHubClient(String repoRoot) async {
    final remote = await resolveGitRemote(runner, repoRoot);

    return GitHubClient(runner: runner, owner: remote.owner, repo: remote.repo);
  }

  /// A `<family>/<issueNumber>-<slug>` head-branch pattern, shared by
  /// [_findOpenPr] and [_findMergedPr] so open and merged PR lists are
  /// matched identically.
  RegExp _headBranchPattern(int issueNumber) =>
      RegExp('^(${branchFamilies.join('|')})/$issueNumber-');

  List<Map<String, dynamic>> _matchingByHeadBranch(
    List<Map<String, dynamic>> prs,
    int issueNumber,
  ) {
    final pattern = _headBranchPattern(issueNumber);

    return prs.where((pr) {
      final ref = pr['headRefName'] as String?;

      return ref != null && pattern.hasMatch(ref);
    }).toList();
  }

  /// Throws a [CommandFailure] naming every match's PR number if [matches]
  /// has more than one entry — shared by [_findOpenPr] and [_findMergedPr],
  /// which differ only in [kind] (`"open"`/`"merged"`, describing which PR
  /// state was searched).
  void _refuseIfMultipleMatches(
    List<Map<String, dynamic>> matches,
    int issueNumber,
    String kind,
  ) {
    if (matches.length <= 1) return;
    final numbers = matches.map((m) => m['number']).join(', ');
    throw CommandFailure(
      'Multiple $kind PRs match issue #$issueNumber: $numbers.',
    );
  }

  /// The open PR for issue [issueNumber], or `null` if none matches (the
  /// resume path then looks for an already-merged one — see
  /// [_resumeFromMergedPr]).
  Future<_PrInfo?> _findOpenPr(GitHubClient github, int issueNumber) async {
    final prs = await github.listOpenPullRequests();
    final matches = _matchingByHeadBranch(prs, issueNumber);
    if (matches.isEmpty) return null;
    _refuseIfMultipleMatches(matches, issueNumber, 'open');

    final match = matches.single;

    return _PrInfo(
      index: match['number'] as int,
      title: match['title'] as String,
      headSha: match['headRefOid'] as String,
      headRef: match['headRefName'] as String,
      base: match['baseRefName'] as String,
    );
  }

  /// The merged PR for issue [issueNumber], or `null` if none matches (or
  /// the match has no `mergeCommit`, which `gh` should never return for a
  /// merged PR, but is treated as "no usable match" rather than crashing).
  Future<_MergedPrInfo?> _findMergedPr(
    GitHubClient github,
    int issueNumber,
  ) async {
    final prs = await github.listMergedPullRequests();
    final matches = _matchingByHeadBranch(prs, issueNumber);
    if (matches.isEmpty) return null;
    _refuseIfMultipleMatches(matches, issueNumber, 'merged');

    final match = matches.single;
    final mergeCommit = match['mergeCommit'] as Map<String, dynamic>?;
    if (mergeCommit == null) return null;

    return _MergedPrInfo(
      index: match['number'] as int,
      headRef: match['headRefName'] as String,
      base: match['baseRefName'] as String,
      mergeCommitSha: mergeCommit['oid'] as String,
    );
  }

  Future<void> _refuseIfCriteriaUnchecked(
    GitHubClient github,
    int issueNumber,
  ) async {
    final issue = await github.getIssue(issueNumber);
    final unchecked = uncheckedAcceptanceCriteria(
      issue['body'] as String? ?? '',
    );
    if (unchecked.isEmpty) return;

    final list = unchecked.map((item) => '  - [ ] $item').join('\n');
    throw CommandFailure(
      'Issue #$issueNumber has unchecked acceptance criteria — tick them '
      'before finishing:\n$list',
    );
  }

  Future<void> _waitUntilMergeable(GitHubClient github, _PrInfo pr) async {
    var mergeable = await _isMergeable(github, pr.index);
    var attempt = 0;
    while (!mergeable && attempt < timing.mergePollAttempts) {
      await Future<void>.delayed(timing.mergePollDelay);
      mergeable = await _isMergeable(github, pr.index);
      attempt++;
    }
    if (!mergeable) {
      throw CommandFailure(
        'PR #${pr.index} is not mergeable after polling '
        '${timing.mergePollAttempts} time(s). Resolve conflicts and retry.',
      );
    }
  }

  Future<bool> _isMergeable(GitHubClient github, int prIndex) async {
    final pr = await github.getPullRequest(prIndex);

    return pr['mergeable'] == _mergeableState;
  }

  Future<String> _mergeAndVerify(
    String repoRoot,
    GitHubClient github,
    _PrInfo pr,
  ) async {
    final mergeResult = await github.mergePullRequest(
      pr.index,
      commitTitle: pr.title,
    );
    _checkMergeResult(mergeResult, pr.index, pr.base);

    final merged = await github.getPullRequest(pr.index);
    final mergeCommit = merged['mergeCommit'] as Map<String, dynamic>?;
    if (merged['state'] != 'MERGED' || mergeCommit == null) {
      throw CommandFailure(
        'Merge call succeeded but PR #${pr.index} does not yet show '
        'merged:true with a mergeCommit — retry finish shortly.',
      );
    }
    final mergeCommitSha = mergeCommit['oid'] as String;
    await _verifyRefMoved(repoRoot, pr, mergeCommitSha);

    return mergeCommitSha;
  }

  void _checkMergeResult(ProcessResult result, int prIndex, String base) {
    if (result.exitCode == 0) return;

    final text = '${result.stdout}\n${result.stderr}'.toLowerCase();
    if (text.contains('not mergeable') || text.contains('conflict')) {
      throw CommandFailure(
        'Merge refused (CONFLICT): PR #$prIndex has a conflict with $base. '
        'Merge $base into the branch, resolve and push, then retry — do '
        'not retry blindly.',
      );
    }
    throw CommandFailure(
      'Merge failed for PR #$prIndex: ${result.stdout}\n${result.stderr}',
    );
  }

  Future<void> _verifyRefMoved(
    String repoRoot,
    _PrInfo pr,
    String mergeCommitSha,
  ) async {
    await Future<void>.delayed(timing.postMergeWait);
    final lsRemote = await runner.run('git', [
      'ls-remote',
      'origin',
      'refs/heads/${pr.base}',
    ], workingDirectory: repoRoot);
    if (lsRemote.exitCode != 0) {
      throw CommandFailure(
        'git ls-remote origin refs/heads/${pr.base} failed: '
        '${lsRemote.stderr}',
      );
    }
    final remoteSha = _firstToken(lsRemote.stdout as String);
    if (remoteSha != mergeCommitSha) {
      throw CommandFailure(
        'GitHub reports merged:true but origin/${pr.base} is still at '
        '"${remoteSha ?? '(none)'}", not merge commit "$mergeCommitSha" — '
        'refusing to close the issue. GitHub can report merged:true '
        'without moving the ref; never trust the API alone.',
      );
    }

    final fetch = await runner.run('git', [
      'fetch',
      'origin',
      pr.base,
    ], workingDirectory: repoRoot);
    if (fetch.exitCode != 0) {
      throw CommandFailure(
        'git fetch origin ${pr.base} failed: ${fetch.stderr}',
      );
    }
    final ancestor = await runner.run('git', [
      'merge-base',
      '--is-ancestor',
      pr.headSha,
      mergeCommitSha,
    ], workingDirectory: repoRoot);
    if (ancestor.exitCode != 0) {
      throw CommandFailure(
        '${pr.headSha} (the PR head) is not an ancestor of merge commit '
        '$mergeCommitSha — refusing to close the issue.',
      );
    }
  }

  String? _firstToken(String text) {
    final trimmed = text.trim();

    return trimmed.isEmpty ? null : trimmed.split(RegExp(r'\s+')).first;
  }

  Future<void> _removeWorktree(String repoRoot, String headRef) async {
    final worktreeName = _worktreeNameFromRef(headRef);
    final result = await runner.run('git', [
      'worktree',
      'remove',
      p.join('.worktrees', worktreeName),
    ], workingDirectory: repoRoot);
    if (result.exitCode != 0) {
      throw CommandFailure(
        'git worktree remove .worktrees/$worktreeName failed (the merge '
        'already landed — remove the worktree by hand): ${result.stderr}',
      );
    }
    out(
      'Removed worktree .worktrees/$worktreeName (local branch $headRef '
      'kept).',
    );
  }

  String _worktreeNameFromRef(String ref) {
    final pattern = RegExp('^(${branchFamilies.join('|')})/(\\d+)-');
    final match = pattern.firstMatch(ref);
    if (match == null) {
      throw CommandFailure(
        'Could not determine a worktree name from branch ref "$ref".',
      );
    }

    return match.group(_issueNumberGroup) ?? '';
  }

  Future<void> _fastForwardMainCheckout(
    String repoRoot,
    String base,
    String mergeCommitSha,
  ) async {
    final current = await runner.run('git', [
      'rev-parse',
      '--abbrev-ref',
      'HEAD',
    ], workingDirectory: repoRoot);
    final currentBranch = (current.stdout as String).trim();
    if (currentBranch != base) {
      err(
        'Main checkout is on "$currentBranch", not "$base" — not '
        'fast-forwarding automatically; do it by hand.',
      );

      return;
    }
    final ff = await runner.run('git', [
      'merge',
      '--ff-only',
      'origin/$base',
    ], workingDirectory: repoRoot);
    if (ff.exitCode != 0) {
      throw CommandFailure('Fast-forwarding $base failed: ${ff.stderr}');
    }
    out('Fast-forwarded main checkout $base to $mergeCommitSha.');
  }

  /// The resume path's equivalent of [_fastForwardMainCheckout]: fetches
  /// [base] fresh (the normal merge path already fetched it as part of
  /// [_verifyRefMoved], but resuming skips that step entirely) and, if the
  /// checkout is on [base], fast-forwards to it. Returns the resulting
  /// `HEAD` SHA either way — [base]'s current tip on the main checkout, or
  /// (if the checkout isn't on [base]) whatever `HEAD` already was, since
  /// then nothing moved and [err] already said so.
  Future<String> _fetchAndFastForward(String repoRoot, String base) async {
    final fetch = await runner.run('git', [
      'fetch',
      'origin',
      base,
    ], workingDirectory: repoRoot);
    if (fetch.exitCode != 0) {
      throw CommandFailure('git fetch origin $base failed: ${fetch.stderr}');
    }
    final remoteRev = await runner.run('git', [
      'rev-parse',
      'origin/$base',
    ], workingDirectory: repoRoot);
    if (remoteRev.exitCode != 0) {
      throw CommandFailure(
        'git rev-parse origin/$base failed: ${remoteRev.stderr}',
      );
    }
    final remoteSha = (remoteRev.stdout as String).trim();

    final current = await runner.run('git', [
      'rev-parse',
      '--abbrev-ref',
      'HEAD',
    ], workingDirectory: repoRoot);
    final currentBranch = (current.stdout as String).trim();
    if (currentBranch != base) {
      err(
        'Main checkout is on "$currentBranch", not "$base" — not '
        'fast-forwarding automatically; do it by hand.',
      );

      return await _currentHeadSha(repoRoot);
    }

    final ff = await runner.run('git', [
      'merge',
      '--ff-only',
      'origin/$base',
    ], workingDirectory: repoRoot);
    if (ff.exitCode != 0) {
      throw CommandFailure('Fast-forwarding $base failed: ${ff.stderr}');
    }
    out('Fast-forwarded main checkout $base to $remoteSha.');

    return remoteSha;
  }

  Future<String> _currentHeadSha(String repoRoot) async {
    final head = await runner.run('git', [
      'rev-parse',
      'HEAD',
    ], workingDirectory: repoRoot);

    return (head.stdout as String).trim();
  }

  /// Runs [verificationMelosScripts] against merged `development` in
  /// `outcome.repoRoot` (the just-fast-forwarded main checkout) and either
  /// closes the issue (every check passed) or leaves it open and
  /// re-labelled (a check failed) — see the class doc comment.
  Future<void> _verifyThenCloseOrRelabel(
    GitHubClient github,
    _MergeOutcome outcome,
  ) async {
    final issueNumber = outcome.issueNumber;
    final mergeCommitSha = outcome.mergeCommitSha;
    final base = outcome.base;

    final suite = await runVerificationSuite(
      runner: runner,
      repoRoot: outcome.repoRoot,
      out: out,
    );
    final failure = suite.firstFailure;
    if (failure == null) {
      final commentBody =
          'Merged as $mergeCommitSha into $base. Verified against merged '
          '$base via `melos run <script>` for: '
          '${suite.passedScripts.join(', ')}.';
      await _closeOut(github, issueNumber, mergeCommitSha, commentBody);

      return;
    }

    await github.removeLabelIfPresent(issueNumber, _reviewLabel);
    await github.addLabel(issueNumber, _inProgressLabel);

    throw CommandFailure(
      'Verification check "${failure.script}" failed against merged '
      '$base (merge commit $mergeCommitSha). Issue #$issueNumber left '
      'open and re-labelled "$_inProgressLabel" — shared history on '
      '$base is never rewritten, so fix this with a bugfix/* forward-fix '
      '(or a revert), not a rebase, then re-run finish.',
    );
  }

  Future<void> _closeOut(
    GitHubClient github,
    int issueNumber,
    String mergeCommitSha,
    String commentBody,
  ) async {
    await github.closeAsVerified(issueNumber, commentBody);
    out('Closed issue #$issueNumber (merge $mergeCommitSha).');
  }
}

/// Tunable timing knobs for [FinishCommand] — how long to wait between
/// mergeable polls and after merging before checking the base ref moved.
/// Tests override these to zero to avoid real waiting.
class FinishTiming {
  /// Creates a timing configuration.
  const FinishTiming({
    this.mergePollAttempts = 5,
    this.mergePollDelay = const Duration(seconds: 2),
    this.postMergeWait = const Duration(seconds: 2),
  });

  /// How many extra times to poll `mergeable` after the first check.
  final int mergePollAttempts;

  /// How long to wait between mergeable polls.
  final Duration mergePollDelay;

  /// How long to wait after merging before checking `git ls-remote`.
  final Duration postMergeWait;
}

class _PrInfo {
  const _PrInfo({
    required this.index,
    required this.title,
    required this.headSha,
    required this.headRef,
    required this.base,
  });

  final int index;

  /// The PR's title — used as the merge commit's subject.
  final String title;
  final String headSha;
  final String headRef;
  final String base;
}

/// What [FinishCommand._findMergedPr] needs from a merged PR to drive the
/// resume path: no `title`/`headSha` (never re-merged, so nothing needs a
/// merge-commit subject or a ref-moved check against the PR's own head
/// any more) but a [mergeCommitSha] instead (the merge that already
/// landed).
class _MergedPrInfo {
  const _MergedPrInfo({
    required this.index,
    required this.headRef,
    required this.base,
    required this.mergeCommitSha,
  });

  final int index;
  final String headRef;
  final String base;

  /// The SHA of the merge commit that already landed [headRef] on [base].
  final String mergeCommitSha;
}

/// Bundles what `FinishCommand._verifyThenCloseOrRelabel` needs once the
/// merge has landed and the main checkout has been fast-forwarded — kept
/// as one object rather than four parameters (solid_lints'
/// `number_of_parameters` threshold).
class _MergeOutcome {
  const _MergeOutcome({
    required this.issueNumber,
    required this.mergeCommitSha,
    required this.base,
    required this.repoRoot,
  });

  /// The GitHub issue number `finish` was run for.
  final int issueNumber;

  /// The SHA of the merge commit that landed on [base].
  final String mergeCommitSha;

  /// The branch the PR was merged into (e.g. `development`).
  final String base;

  /// The main checkout's filesystem path, already fast-forwarded to
  /// [mergeCommitSha].
  final String repoRoot;
}
