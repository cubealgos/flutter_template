import 'dart:convert';
import 'dart:io';

import 'package:tooling/src/github_throttle.dart';
import 'package:tooling/src/process_runner.dart';

/// GitHub issue/PR/label operations for one repository, driven entirely
/// through the `gh` CLI — never a raw HTTPS call and never a token read or
/// passed by this tool itself, since `gh` already holds its own login.
///
/// Every call shells out via [runner], so tests inject a fake in place of
/// [runner] and never hit the network. Every call passes an explicit
/// `--repo owner/repo` flag rather than relying on `gh` to infer the repo
/// from the working directory's git remote, which a disposable test
/// fixture (often a local file path, never a real `github.com` remote)
/// can't answer. Content-creating calls (labels, comments, issue edits,
/// the merge itself) are routed through [throttle] so they never outrun
/// GitHub's secondary rate limit (80/min, 500/hour) — see [GitHubThrottle].
class GitHubClient {
  /// Creates a client for `<owner>/<repo>`, issuing every call through
  /// [runner]. [throttle] defaults to [GitHubThrottle]'s own defaults;
  /// tests inject one with a fake clock/sleeper to assert on spacing and
  /// retries without a real delay.
  GitHubClient({
    required this.runner,
    required this.owner,
    required this.repo,
    GitHubThrottle? throttle,
  }) : throttle = throttle ?? GitHubThrottle();

  /// The process runner `gh` is invoked through.
  final ProcessRunner runner;

  /// The repository owner (user or org).
  final String owner;

  /// The repository name.
  final String repo;

  /// Spaces and retries every content-creating call below.
  final GitHubThrottle throttle;

  String get _repoSlug => '$owner/$repo';

  /// Every currently open pull request, with the fields `finish` needs to
  /// find the one for a given issue and merge it.
  Future<List<Map<String, dynamic>>> listOpenPullRequests() =>
      _listPullRequests(
        state: 'open',
        jsonFields: 'number,title,headRefName,headRefOid,baseRefName,mergeable',
      );

  /// Every merged pull request for this repo, with the fields `finish`
  /// needs to resume when a PR for an issue is already merged but no open
  /// PR matches it any more (`finish`'s resume path — the merge already
  /// landed on a prior run, e.g. one where post-merge verification then
  /// failed). Unlike [listOpenPullRequests], includes `mergeCommit` (its
  /// `oid` is what the resume path verifies `development` against) instead
  /// of `mergeable`, which is meaningless once merged.
  Future<List<Map<String, dynamic>>> listMergedPullRequests() =>
      _listPullRequests(
        state: 'merged',
        jsonFields: 'number,title,headRefName,baseRefName,mergeCommit',
      );

  Future<List<Map<String, dynamic>>> _listPullRequests({
    required String state,
    required String jsonFields,
  }) async {
    final result = await _run([
      'pr',
      'list',
      '--state',
      state,
      '--limit',
      '100',
      '--json',
      jsonFields,
    ]);

    return (_decode(result, ['pr', 'list']) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  /// The pull request numbered [number]: `mergeable` is one of GitHub's
  /// `MERGEABLE`/`CONFLICTING`/`UNKNOWN` strings, and `mergeCommit` is
  /// either `null` or a `{"oid": <sha>}` map once merged.
  Future<Map<String, dynamic>> getPullRequest(int number) async {
    final result = await _run([
      'pr',
      'view',
      '$number',
      '--json',
      _pullRequestJsonFields,
    ]);

    return _decode(result, ['pr', 'view']) as Map<String, dynamic>;
  }

  /// Plain-merges pull request [number] (`--merge`, never squash/rebase),
  /// using [commitTitle] as the merge commit's subject, and deletes its
  /// remote head branch. Returns the raw process result — callers must
  /// inspect it themselves, since a conflict surfaces as a non-zero exit
  /// with a "not mergeable" message rather than a distinct field.
  Future<ProcessResult> mergePullRequest(
    int number, {
    required String commitTitle,
  }) => throttle.guard(
    () => _run([
      'pr',
      'merge',
      '$number',
      '--merge',
      '--delete-branch',
      '--subject',
      commitTitle,
    ]),
  );

  /// The issue numbered [number] (`body`, `labels`, `title`, `state` —
  /// `state` is `OPEN` or `CLOSED`, read by `finish`'s resume path to
  /// refuse resuming an issue that's already closed).
  Future<Map<String, dynamic>> getIssue(int number) async {
    final result = await _run([
      'issue',
      'view',
      '$number',
      '--json',
      'body,labels,title,state',
    ]);

    return _decode(result, ['issue', 'view']) as Map<String, dynamic>;
  }

  /// Adds the label named [name] to issue [number] (additive — existing
  /// labels are kept). Throws [GitHubRequestFailure] if [name] doesn't
  /// exist on the repo — `gh` itself refuses rather than silently creating
  /// it, which is exactly the "never hardcoded, always a real label"
  /// guarantee this call relies on.
  Future<void> addLabel(int number, String name) =>
      _mutate(['issue', 'edit', '$number', '--add-label', name]);

  /// Removes the label named [name] from issue [number], if present. A
  /// no-op if the issue doesn't carry that label (never asks `gh` to
  /// remove a label that isn't there).
  Future<void> removeLabelIfPresent(int number, String name) async {
    final issue = await getIssue(number);
    final labels = (issue['labels'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final present = labels.any((label) => label['name'] == name);
    if (!present) return;

    await _mutate(['issue', 'edit', '$number', '--remove-label', name]);
  }

  /// Closes issue [number] explicitly (never via a `Closes #N` keyword).
  Future<void> closeIssue(int number) => _mutate(['issue', 'close', '$number']);

  /// Posts [body] as a comment on issue [number].
  Future<void> commentOnIssue(int number, String body) =>
      _mutate(['issue', 'comment', '$number', '--body', body]);

  /// Closes issue [number] as verified: removes both status labels, posts
  /// [commentBody], then closes it — the explicit "done" sequence CLAUDE.md
  /// requires once acceptance criteria are confirmed against merged
  /// `development` (never an implicit `Closes #N` keyword).
  Future<void> closeAsVerified(int number, String commentBody) async {
    await removeLabelIfPresent(number, 'status/review');
    await removeLabelIfPresent(number, 'status/in-progress');
    await commentOnIssue(number, commentBody);
    await closeIssue(number);
  }

  Future<ProcessResult> _run(List<String> args) =>
      runner.run('gh', [...args, '--repo', _repoSlug]);

  Future<void> _mutate(List<String> args) async {
    final result = await throttle.guard(() => _run(args));
    if (result.exitCode != 0) {
      throw GitHubRequestFailure(args, result);
    }
  }

  dynamic _decode(ProcessResult result, List<String> args) {
    if (result.exitCode != 0) {
      throw GitHubRequestFailure(args, result);
    }
    final text = (result.stdout as String).trim();

    return text.isEmpty ? null : jsonDecode(text);
  }
}

/// The `--json` field list [GitHubClient.getPullRequest] requests: enough
/// to find a PR's branch/base, poll `mergeable`, and read back the merge
/// commit once merged (`state` is `MERGED`; `gh` has no `merged` field).
const String _pullRequestJsonFields =
    'number,title,headRefName,headRefOid,baseRefName,mergeable,state,'
    'mergeCommit';

/// Thrown when a `gh` call exits non-zero. Carries the argument list (as
/// passed before [GitHubClient] appends `--repo owner/repo`) and the
/// underlying [ProcessResult] so a caller can inspect
/// [ProcessResult.stdout]/[ProcessResult.stderr] for a specific message
/// (e.g. a merge conflict's "not mergeable" text) rather than only seeing
/// [toString].
class GitHubRequestFailure implements Exception {
  /// Creates a failure for the `gh` invocation [args] that produced
  /// [result].
  GitHubRequestFailure(this.args, this.result);

  /// The argument list passed to the `gh` executable (excluding the
  /// trailing `--repo` flag every call appends).
  final List<String> args;

  /// The process result: exit code, stdout and stderr.
  final ProcessResult result;

  @override
  String toString() =>
      'gh ${args.join(' ')} failed (exit ${result.exitCode}): '
              '${result.stderr}'
          .trim();
}
