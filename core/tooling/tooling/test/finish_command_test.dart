import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/finish_command.dart';
import 'package:tooling/src/verification_suite.dart';

import 'support/git_fixture.dart';
import 'support/scripted_process_runner.dart';

/// An `fvmHandler` for [ScriptedProcessRunner] that passes every
/// verification check — the common case for tests that only care about the
/// merge/close path.
ProcessResult _allChecksPass(List<String> _) => passingCheck();

const FinishTiming _noWait = FinishTiming(
  mergePollAttempts: 1,
  mergePollDelay: Duration.zero,
  postMergeWait: Duration.zero,
);

/// The fake issue number and PR index used throughout this file.
const int _issueNumber = 1;
const int _prIndex = 5;

/// One routed response for a fake `gh` invocation — lets each test
/// assemble a [ScriptedProcessRunner] out of small, named, reusable pieces
/// instead of repeating the same if-chain inline.
//
// This file is named for the command under test, not for this private
// routing helper (the only class declared here).
// ignore: solid_lints/prefer_match_file_name
class _GhRoute {
  const _GhRoute(this.command, this.matches, this.handler);

  final String command;
  final bool Function(List<String> args) matches;
  final ProcessResult Function() handler;
}

ScriptedProcessRunner _buildRunner(
  List<_GhRoute> routes, {
  FvmHandler? fvmHandler,
}) => ScriptedProcessRunner((args) {
  final command = ghCommandOf(args);
  for (final route in routes) {
    if (route.command == command && route.matches(args)) {
      return route.handler();
    }
  }

  return jsonResult(null);
}, fvmHandler: fvmHandler);

/// The base branch every fake open PR in this file targets — no test needs
/// a different one, so it's a constant rather than a fifth parameter on
/// [_openPrRoute] (solid_lints' `number_of_parameters` threshold).
const String _openPrBase = 'development';

_GhRoute _openPrRoute({
  required int number,
  required String ref,
  required String sha,
  String title = 'feat(app): add thing (#1)',
}) => _GhRoute(
  'pr list',
  (args) => ghFlagValue(args, '--state') == 'open',
  () => jsonResult([
    {
      'number': number,
      'title': title,
      'headRefName': ref,
      'headRefOid': sha,
      'baseRefName': _openPrBase,
      'mergeable': 'MERGEABLE',
    },
  ]),
);

/// An empty `pr list --state open` response — every resume-path test needs
/// this so `_findOpenPr` finds nothing and falls through to
/// [_mergedPrRoute].
final _GhRoute _noOpenPrRoute = _GhRoute(
  'pr list',
  (args) => ghFlagValue(args, '--state') == 'open',
  () => jsonResult(<dynamic>[]),
);

/// A `pr list --state merged` response with a single merged PR for issue
/// the first issue's branch — the resume path's `_findMergedPr`.
_GhRoute _mergedPrRoute({
  required int number,
  required String ref,
  required String mergeCommitSha,
  String title = 'feat(app): add thing (#1)',
}) => _GhRoute(
  'pr list',
  (args) => ghFlagValue(args, '--state') == 'merged',
  () => jsonResult([
    {
      'number': number,
      'title': title,
      'headRefName': ref,
      'baseRefName': _openPrBase,
      'mergeCommit': {'oid': mergeCommitSha},
    },
  ]),
);

_GhRoute _issueRoute(int number, String body, {String state = 'OPEN'}) =>
    _GhRoute(
      'issue view',
      (args) => args.contains('$number'),
      () => jsonResult({
        'body': body,
        'title': 't',
        'labels': <dynamic>[],
        'state': state,
      }),
    );

_GhRoute _pullStateRoute(
  int index, {
  required bool Function() merged,
  required String Function() mergeCommitSha,
}) => _GhRoute(
  'pr view',
  (args) => args.contains('$index'),
  () => merged()
      ? jsonResult({
          'state': 'MERGED',
          'mergeCommit': {'oid': mergeCommitSha()},
          'mergeable': 'MERGEABLE',
        })
      : jsonResult({'mergeable': 'MERGEABLE', 'state': 'OPEN'}),
);

_GhRoute _mergeRoute(int index, ProcessResult Function() onMerge) =>
    _GhRoute('pr merge', (args) => args.contains('$index'), onMerge);

/// Whether [runner] recorded a `gh` call whose command is [command] and
/// whose args contain [number] — shorthand for the "was this GitHub call
/// made" assertions repeated across this file's tests.
bool _hadGhCall(ScriptedProcessRunner runner, String command, int number) =>
    runner.ghCalls.any(
      (c) => ghCommandOf(c) == command && c.contains('$number'),
    );

/// Runs `finish <_issueNumber>` against [runner] and [repoRoot], writing
/// progress to [out]/[err] — shorthand for the `FinishCommand` construction
/// repeated across this file's tests.
Future<int> _runFinish(
  ScriptedProcessRunner runner,
  void Function(String) out,
  void Function(String) err,
  String repoRoot,
) => FinishCommand(
  runner: runner,
  timing: _noWait,
  out: out,
  err: err,
).run(['$_issueNumber'], repoRoot: repoRoot);

/// The gh routes shared by every test that gets as far as a real merge
/// landing on `origin/development`: an open PR for [headSha], an issue
/// with every acceptance-criteria box ticked, and a PR-view route that
/// flips to `merged:true` (returning [mergeShaOf]'s value) the moment
/// [_mergeRoute]'s handler runs.
List<_GhRoute> _mergeHappyPathRoutes({
  required String headSha,
  required String Function() mergeShaOf,
}) {
  var merged = false;

  return [
    _openPrRoute(number: _prIndex, ref: 'feature/1-add-thing', sha: headSha),
    _issueRoute(_issueNumber, '## Acceptance criteria\n- [x] done\n'),
    _pullStateRoute(_prIndex, merged: () => merged, mergeCommitSha: mergeShaOf),
    _mergeRoute(_prIndex, () {
      merged = true;

      return jsonResult(null);
    }),
  ];
}

/// Creates a worktree for issue #1 on `feature/1-add-thing`, commits a
/// change and pushes it — the branch a fake open PR then points at.
/// Returns the branch's head SHA.
Future<String> _pushFeatureBranch(String mainCheckout) async {
  await runGit([
    'worktree',
    'add',
    '--relative-paths',
    '-b',
    'feature/1-add-thing',
    '.worktrees/1',
    'origin/development',
  ], mainCheckout);
  final worktreeDir = p.join(mainCheckout, '.worktrees', '1');
  File(p.join(worktreeDir, 'CHANGES.md')).writeAsStringSync('change\n');
  await runGit(['add', 'CHANGES.md'], worktreeDir);
  await commitInGit(worktreeDir, 'feat(app): add thing (#1)');
  final headSha = await revParseHead(worktreeDir);
  await runGit(['push', '-q', 'origin', 'feature/1-add-thing'], worktreeDir);

  return headSha;
}

/// Pushes a feature branch straight from [seedCheckout] (no worktree under
/// the main checkout) — used by the resume-path tests, where the branch's
/// worktree is assumed already removed by an earlier `finish` run that got
/// as far as merging before failing at verification. Leaves [seedCheckout]
/// back on `development`. Returns the branch's head SHA.
Future<String> _pushFeatureBranchViaSeed(
  String seedCheckout, {
  String branch = 'feature/1-add-thing',
}) async {
  await runGit([
    'checkout',
    '-q',
    '-b',
    branch,
    'origin/development',
  ], seedCheckout);
  File(p.join(seedCheckout, 'CHANGES.md')).writeAsStringSync('change\n');
  await runGit(['add', 'CHANGES.md'], seedCheckout);
  await commitInGit(seedCheckout, 'feat(app): add thing (#1)');
  final headSha = await revParseHead(seedCheckout);
  await runGit(['push', '-q', 'origin', branch], seedCheckout);
  await runGit(['checkout', '-q', 'development'], seedCheckout);

  return headSha;
}

/// Simulates the forge-side merge from [seedCheckout] (a separate clone),
/// so a real merge commit lands on `origin/development` before `finish`
/// runs. Returns the merge commit's SHA.
Future<String> _simulateForgeMerge(String seedCheckout) async {
  await runGit(['fetch', '-q', 'origin'], seedCheckout);
  await runGit(['checkout', '-q', 'development'], seedCheckout);
  await runGit([
    'merge',
    '--no-ff',
    '--no-edit',
    'origin/feature/1-add-thing',
  ], seedCheckout);
  final mergeSha = await revParseHead(seedCheckout);
  await runGit(['push', '-q', 'origin', 'development'], seedCheckout);

  return mergeSha;
}

void main() {
  final buffer = StringBuffer();
  void out(String m) => buffer.writeln('OUT: $m');
  void err(String m) => buffer.writeln('ERR: $m');

  setUp(buffer.clear);

  test('happy path: merge, verify via ls-remote, remove worktree, run the '
      'verification suite against merged development, then close', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final main = fixture.mainCheckout.path;

    final headSha = await _pushFeatureBranch(main);
    final mergeSha = await _simulateForgeMerge(fixture.seedCheckout.path);

    final runner = _buildRunner(
      _mergeHappyPathRoutes(headSha: headSha, mergeShaOf: () => mergeSha),
      fvmHandler: _allChecksPass,
    );

    final exitCode = await _runFinish(runner, out, err, main);

    expect(exitCode, 0, reason: buffer.toString());
    expect(Directory(p.join(main, '.worktrees', '1')).existsSync(), isFalse);
    expect(await revParseHead(main), mergeSha);
    expect(
      runner.fvmCalls.map(melosScriptOf),
      verificationMelosScripts,
      reason: 'every verification check must run, in order, once merged',
    );

    expect(_hadGhCall(runner, 'issue close', _issueNumber), isTrue);

    final commentCall = runner.ghCalls.firstWhere(
      (c) => ghCommandOf(c) == 'issue comment' && c.contains('$_issueNumber'),
    );
    final commentBody = ghFlagValue(commentCall, '--body');
    expect(commentBody, isNotNull);
    expect(commentBody, contains(mergeSha));
    for (final script in verificationMelosScripts) {
      expect(commentBody, contains(script));
    }
  });

  test('the merge uses the PR title as the merge commit subject', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final main = fixture.mainCheckout.path;

    final headSha = await _pushFeatureBranch(main);
    final mergeSha = await _simulateForgeMerge(fixture.seedCheckout.path);

    var merged = false;
    final runner = _buildRunner([
      _openPrRoute(number: _prIndex, ref: 'feature/1-add-thing', sha: headSha),
      _issueRoute(_issueNumber, '## Acceptance criteria\n- [x] done\n'),
      _pullStateRoute(
        _prIndex,
        merged: () => merged,
        mergeCommitSha: () => mergeSha,
      ),
      _mergeRoute(_prIndex, () {
        merged = true;

        return jsonResult(null);
      }),
    ], fvmHandler: _allChecksPass);

    final exitCode = await _runFinish(runner, out, err, main);

    expect(exitCode, 0, reason: buffer.toString());
    final mergeCall = runner.ghCalls.firstWhere(
      (c) => ghCommandOf(c) == 'pr merge',
    );
    expect(ghFlagValue(mergeCall, '--subject'), 'feat(app): add thing (#1)');
    expect(mergeCall, contains('--merge'));
    expect(mergeCall, contains('--delete-branch'));
  });

  test('a failing verification check leaves the issue open, relabelled '
      'status/in-progress, and never closes it', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final main = fixture.mainCheckout.path;

    final headSha = await _pushFeatureBranch(main);
    final mergeSha = await _simulateForgeMerge(fixture.seedCheckout.path);
    final failingScript = verificationMelosScripts[1];

    final runner = _buildRunner(
      _mergeHappyPathRoutes(headSha: headSha, mergeShaOf: () => mergeSha),
      fvmHandler: (args) => melosScriptOf(args) == failingScript
          ? failingCheck()
          : passingCheck(),
    );

    final exitCode = await _runFinish(runner, out, err, main);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains(failingScript));
    expect(buffer.toString(), contains('bugfix/*'));
    expect(
      await revParseHead(main),
      mergeSha,
      reason: 'the merge itself already landed — only closing is refused',
    );
    expect(runner.fvmCalls.map(melosScriptOf), [
      verificationMelosScripts.first,
      failingScript,
    ], reason: 'must stop at the first failing check');
    expect(
      _hadGhCall(runner, 'issue close', _issueNumber),
      isFalse,
      reason: 'must never close the issue when a check fails',
    );
    expect(
      runner.ghCalls.any((c) => ghCommandOf(c) == 'issue comment'),
      isFalse,
    );

    final addLabelCall = runner.ghCalls.firstWhere(
      (c) => ghCommandOf(c) == 'issue edit' && c.contains('$_issueNumber'),
    );
    expect(ghFlagValue(addLabelCall, '--add-label'), 'status/in-progress');
  });

  test(
    'refuses while acceptance criteria are unchecked, listing them',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);

      final runner = _buildRunner([
        _openPrRoute(
          number: _prIndex,
          ref: 'feature/1-add-thing',
          sha: 'deadbeef',
        ),
        _issueRoute(
          1,
          '## Acceptance criteria\n- [ ] first thing\n- [x] second thing\n',
        ),
      ]);

      final command = FinishCommand(
        runner: runner,
        timing: _noWait,
        out: out,
        err: err,
      );
      final exitCode = await command.run([
        '$_issueNumber',
      ], repoRoot: fixture.mainCheckout.path);

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('unchecked acceptance criteria'));
      expect(buffer.toString(), contains('first thing'));
      expect(buffer.toString(), isNot(contains('second thing')));
    },
  );

  test('treats a "not mergeable" merge failure as a conflict, not a retry '
      'target', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);

    final runner = _buildRunner([
      _openPrRoute(
        number: _prIndex,
        ref: 'feature/1-add-thing',
        sha: 'deadbeef',
      ),
      _issueRoute(_issueNumber, '## Acceptance criteria\n- [x] done\n'),
      _pullStateRoute(_prIndex, merged: () => false, mergeCommitSha: () => ''),
      _mergeRoute(
        _prIndex,
        () => failedResult(
          stderr:
              'X Pull request #5 is not mergeable: the merge commit '
              'could not be cleanly created.',
        ),
      ),
    ]);

    final command = FinishCommand(
      runner: runner,
      timing: _noWait,
      out: out,
      err: err,
    );
    final exitCode = await command.run([
      '$_issueNumber',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('CONFLICT'));
    final mergeCalls = runner.ghCalls
        .where((c) => ghCommandOf(c) == 'pr merge')
        .length;
    expect(mergeCalls, 1, reason: 'must not blindly retry a conflict');
  });

  test(
    'refuses to close when the API says merged but the ref did not move',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);

      var merged = false;
      const staleSha = '0123456789abcdef0123456789abcdef01234567';
      final runner = _buildRunner([
        _openPrRoute(
          number: _prIndex,
          ref: 'feature/1-add-thing',
          sha: 'deadbeef',
        ),
        _issueRoute(_issueNumber, '## Acceptance criteria\n- [x] done\n'),
        _pullStateRoute(
          _prIndex,
          merged: () => merged,
          mergeCommitSha: () => staleSha,
        ),
        _mergeRoute(_prIndex, () {
          merged = true;

          return jsonResult(null);
        }),
      ]);

      final command = FinishCommand(
        runner: runner,
        timing: _noWait,
        out: out,
        err: err,
      );
      final exitCode = await command.run([
        '$_issueNumber',
      ], repoRoot: fixture.mainCheckout.path);

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('merged:true'));
      expect(
        _hadGhCall(runner, 'issue close', _issueNumber),
        isFalse,
        reason: 'must never close the issue when the ref did not move',
      );
    },
  );

  test('refuses when no open PR matches the issue', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);

    final runner = _buildRunner([
      _GhRoute('pr list', (_) => true, () => jsonResult(<dynamic>[])),
    ]);

    final command = FinishCommand(
      runner: runner,
      timing: _noWait,
      out: out,
      err: err,
    );
    final exitCode = await command.run([
      '$_issueNumber',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('No open PR found'));
  });

  test('resumes when no open PR matches but a merged one does: skips the '
      'merge, verifies against current development, then closes', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final main = fixture.mainCheckout.path;
    final seed = fixture.seedCheckout.path;

    await _pushFeatureBranchViaSeed(seed);
    final mergeSha = await _simulateForgeMerge(seed);

    final runner = _buildRunner([
      _noOpenPrRoute,
      _mergedPrRoute(
        number: _prIndex,
        ref: 'feature/1-add-thing',
        mergeCommitSha: mergeSha,
      ),
      _issueRoute(_issueNumber, '## Acceptance criteria\n- [x] done\n'),
    ], fvmHandler: _allChecksPass);

    final exitCode = await _runFinish(runner, out, err, main);

    expect(exitCode, 0, reason: buffer.toString());
    expect(
      buffer.toString().toLowerCase(),
      contains('resum'),
      reason: 'must say clearly that it is resuming, not merging',
    );
    expect(await revParseHead(main), mergeSha);
    expect(runner.fvmCalls.map(melosScriptOf), verificationMelosScripts);
    expect(
      runner.ghCalls.any((c) => ghCommandOf(c) == 'pr merge'),
      isFalse,
      reason: 'must never re-merge an already-merged PR',
    );
    expect(_hadGhCall(runner, 'issue close', _issueNumber), isTrue);
  });

  test('resume path leaves the issue open and relabelled when verification '
      'fails again', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final main = fixture.mainCheckout.path;
    final seed = fixture.seedCheckout.path;
    final failingScript = verificationMelosScripts[1];

    await _pushFeatureBranchViaSeed(seed);
    final mergeSha = await _simulateForgeMerge(seed);

    final runner = _buildRunner(
      [
        _noOpenPrRoute,
        _mergedPrRoute(
          number: _prIndex,
          ref: 'feature/1-add-thing',
          mergeCommitSha: mergeSha,
        ),
        _issueRoute(_issueNumber, '## Acceptance criteria\n- [x] done\n'),
      ],
      fvmHandler: (args) => melosScriptOf(args) == failingScript
          ? failingCheck()
          : passingCheck(),
    );

    final exitCode = await _runFinish(runner, out, err, main);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains(failingScript));
    expect(_hadGhCall(runner, 'issue close', _issueNumber), isFalse);
    final addLabelCall = runner.ghCalls.firstWhere(
      (c) => ghCommandOf(c) == 'issue edit' && c.contains('$_issueNumber'),
    );
    expect(ghFlagValue(addLabelCall, '--add-label'), 'status/in-progress');
  });

  test('keeps the original "no open PR" error when there is no PR at all, '
      'open or merged', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);

    final runner = _buildRunner([
      _GhRoute('pr list', (_) => true, () => jsonResult(<dynamic>[])),
    ]);

    final exitCode = await _runFinish(
      runner,
      out,
      err,
      fixture.mainCheckout.path,
    );

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('No open PR found'));
  });

  test(
    "does not resume when the merged PR's issue is already closed",
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final seed = fixture.seedCheckout.path;

      await _pushFeatureBranchViaSeed(seed);
      final mergeSha = await _simulateForgeMerge(seed);

      final runner = _buildRunner([
        _noOpenPrRoute,
        _mergedPrRoute(
          number: _prIndex,
          ref: 'feature/1-add-thing',
          mergeCommitSha: mergeSha,
        ),
        _issueRoute(
          _issueNumber,
          '## Acceptance criteria\n- [x] done\n',
          state: 'CLOSED',
        ),
      ]);

      final exitCode = await _runFinish(
        runner,
        out,
        err,
        fixture.mainCheckout.path,
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('No open PR found'));
    },
  );
}
