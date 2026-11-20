import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/branch_families.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/fvmrc.dart';
import 'package:tooling/src/git_remote_info.dart';
import 'package:tooling/src/github_client.dart';
import 'package:tooling/src/main_checkout.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/worktree_link_check.dart';

/// The number of positional arguments `branch_new` takes: family, N, slug.
const int _expectedArgCount = 3;

/// `branch_new <family> <N> <slug>`: creates `.worktrees/<N>/` on a new
/// `<family>/<N>-<slug>` branch and labels GitHub issue `<N>`
/// `status/in-progress`. See `CLAUDE.md` for the workflow this implements.
class BranchNewCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; tests
  /// override them to capture output instead of printing it.
  BranchNewCommand({
    required this.runner,
    this.out = _defaultOut,
    this.err = _defaultErr,
  });

  /// The process runner `git`/`gh` are invoked through.
  final ProcessRunner runner;

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
    final request = _parseArgs(args);
    await ensureMainCheckout(runner, repoRoot);
    _refuseIfWorktreeExists(repoRoot, request.number);
    await _refuseIfBranchExists(repoRoot, request.branch);

    await _fetchBase(repoRoot, request.base);
    await _addWorktree(repoRoot, request);
    _verifyLink(repoRoot, request.number);
    out(
      'Created worktree .worktrees/${request.number} on branch '
      '${request.branch} (from origin/${request.base}).',
    );

    await _setUpFvm(repoRoot, request.number);
    out('Pinned .worktrees/${request.number} to the .fvmrc Flutter SDK.');

    await _labelIssue(repoRoot, request);
  }

  _BranchNewRequest _parseArgs(List<String> args) {
    if (args.length != _expectedArgCount) {
      throw CommandFailure(
        'Usage: branch_new <family> <N> <slug>',
        exitCode: usageExitCode,
      );
    }
    final family = args.first;
    final number = args[1];
    final slug = args[2];

    if (!branchFamilies.contains(family)) {
      throw CommandFailure(
        'Unknown family "$family". Valid families: '
        '${branchFamilies.join(', ')}.',
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(number)) {
      throw CommandFailure(
        'Issue number must be a positive integer, got "$number".',
      );
    }
    if (!slugPattern.hasMatch(slug)) {
      throw CommandFailure(
        'Slug must be lowercase kebab-case (e.g. "add-widget"), got '
        '"$slug".',
      );
    }

    return _BranchNewRequest(
      family: family,
      number: number,
      slug: slug,
      base: baseBranchFor(family),
    );
  }

  void _refuseIfWorktreeExists(String repoRoot, String number) {
    final dir = Directory(p.join(repoRoot, '.worktrees', number));
    if (dir.existsSync()) {
      throw CommandFailure(
        '.worktrees/$number already exists — refusing to overwrite.',
      );
    }
  }

  Future<void> _refuseIfBranchExists(String repoRoot, String branch) async {
    final result = await runner.run('git', [
      'rev-parse',
      '--verify',
      '--quiet',
      'refs/heads/$branch',
    ], workingDirectory: repoRoot);
    if (result.exitCode == 0) {
      throw CommandFailure(
        'Branch "$branch" already exists — refusing to overwrite.',
      );
    }
  }

  Future<void> _fetchBase(String repoRoot, String base) async {
    final result = await runner.run('git', [
      'fetch',
      'origin',
      base,
    ], workingDirectory: repoRoot);
    if (result.exitCode != 0) {
      throw CommandFailure('git fetch origin $base failed: ${result.stderr}');
    }
  }

  Future<void> _addWorktree(String repoRoot, _BranchNewRequest request) async {
    final result = await runner.run('git', [
      'worktree',
      'add',
      '--relative-paths',
      '-b',
      request.branch,
      p.join('.worktrees', request.number),
      'origin/${request.base}',
    ], workingDirectory: repoRoot);
    if (result.exitCode != 0) {
      throw CommandFailure('git worktree add failed: ${result.stderr}');
    }
  }

  void _verifyLink(String repoRoot, String number) {
    final check = verifyRelativeWorktreeLink(
      repoRoot: repoRoot,
      worktreeName: number,
    );
    if (!check.isRelative) {
      throw CommandFailure(
        'Worktree link is not relative: ${check.reason} '
        '(git worktree add --relative-paths did not produce a relocatable '
        'link).',
      );
    }
  }

  Future<void> _setUpFvm(String repoRoot, String number) async {
    final version = readFvmrcVersion(repoRoot);
    final worktreeDir = p.join(repoRoot, '.worktrees', number);

    // `Process.run` (what `SystemProcessRunner` uses) closes the child's
    // stdin for us, so `fvm` can't block on an interactive prompt reading
    // it — but `--force` still matters: without it, a version mismatch or
    // an unrecognized project shape makes fvm refuse outright rather than
    // just proceeding, seen hanging on exactly this.
    final result = await runner.run('fvm', [
      'use',
      version,
      '--skip-pub-get',
      '--force',
    ], workingDirectory: worktreeDir);
    if (result.exitCode != 0) {
      throw CommandFailure(
        'fvm use $version failed in .worktrees/$number: ${result.stderr}',
      );
    }

    _verifyFvmLink(worktreeDir, number, version);
  }

  void _verifyFvmLink(String worktreeDir, String number, String version) {
    if (!fvmSdkLinked(worktreeDir)) {
      throw CommandFailure(
        'fvm use $version reported success, but '
        '.worktrees/$number/.fvm/flutter_sdk/bin/dart does not resolve — '
        "the worktree's pinned-SDK link is broken.",
      );
    }
  }

  /// Labels the issue `status/in-progress`, then — if [request]'s family
  /// maps to one via [typeLabelFor] — the matching `type/*` label too
  /// (`release`/`hotfix` map to nothing and are silently skipped).
  Future<void> _labelIssue(String repoRoot, _BranchNewRequest request) async {
    final remote = await resolveGitRemote(runner, repoRoot);
    final github = GitHubClient(
      runner: runner,
      owner: remote.owner,
      repo: remote.repo,
    );
    final number = int.parse(request.number);

    await github.addLabel(number, 'status/in-progress');
    out('Labeled issue #${request.number} status/in-progress.');

    final typeLabel = typeLabelFor(request.family);
    if (typeLabel != null) {
      await github.addLabel(number, typeLabel);
      out('Labeled issue #${request.number} $typeLabel.');
    }
  }
}

class _BranchNewRequest {
  const _BranchNewRequest({
    required this.family,
    required this.number,
    required this.slug,
    required this.base,
  });

  final String family;
  final String number;
  final String slug;
  final String base;

  String get branch => '$family/$number-$slug';
}
