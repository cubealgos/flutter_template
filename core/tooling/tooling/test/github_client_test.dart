import 'package:test/test.dart';
import 'package:tooling/src/github_client.dart';
import 'package:tooling/src/github_throttle.dart';

import 'support/scripted_process_runner.dart';

const int _issueNumber = 11;
const int _prIndex = 3;

/// Fakes `gh issue view` with a single-label response ([labelName]),
/// recording every call into [calls], and no-ops (returning `null`) every
/// other call — shared by `removeLabelIfPresent`'s "present" test and
/// `closeAsVerified`'s ordering test, which both start from "the issue
/// carries exactly this one label".
GhHandler _issueViewWithOneLabel(List<List<String>> calls, String labelName) {
  return (args) {
    calls.add(args);
    if (ghCommandOf(args) == 'issue view') {
      return jsonResult({
        'body': '',
        'title': '',
        'labels': [
          {'name': labelName},
        ],
      });
    }

    return jsonResult(null);
  };
}

void main() {
  GitHubClient buildClient(GhHandler handler) => GitHubClient(
    runner: ScriptedProcessRunner(handler),
    owner: 'example-org',
    repo: 'my_app',
  );

  test('listOpenPullRequests builds the right args and decodes JSON', () async {
    final runner = ScriptedProcessRunner(
      (_) => jsonResult([
        {
          'number': _prIndex,
          'title': 'feat(app): add thing (#1)',
          'headRefName': 'feature/1-add-thing',
          'headRefOid': 'deadbeef',
          'baseRefName': 'development',
          'mergeable': 'MERGEABLE',
        },
      ]),
    );
    final github = GitHubClient(
      runner: runner,
      owner: 'example-org',
      repo: 'my_app',
    );

    final prs = await github.listOpenPullRequests();

    expect(prs.single['number'], _prIndex);
    final call = runner.ghCalls.single;
    expect(ghCommandOf(call), 'pr list');
    expect(call, containsAllInOrder(['--state', 'open']));
    expect(ghFlagValue(call, '--repo'), 'example-org/my_app');
  });

  test(
    'listMergedPullRequests builds the right args and decodes JSON',
    () async {
      final runner = ScriptedProcessRunner(
        (_) => jsonResult([
          {
            'number': _prIndex,
            'title': 'feat(app): add thing (#1)',
            'headRefName': 'feature/1-add-thing',
            'baseRefName': 'development',
            'mergeCommit': {'oid': 'deadbeef'},
          },
        ]),
      );
      final github = GitHubClient(
        runner: runner,
        owner: 'example-org',
        repo: 'my_app',
      );

      final prs = await github.listMergedPullRequests();

      expect(prs.single['number'], _prIndex);
      final call = runner.ghCalls.single;
      expect(ghCommandOf(call), 'pr list');
      expect(call, containsAllInOrder(['--state', 'merged']));
      expect(ghFlagValue(call, '--json'), contains('mergeCommit'));
      expect(ghFlagValue(call, '--repo'), 'example-org/my_app');
    },
  );

  test('getIssue requests state alongside body/labels/title', () async {
    final runner = ScriptedProcessRunner(
      (_) => jsonResult({
        'body': '',
        'title': '',
        'labels': <dynamic>[],
        'state': 'OPEN',
      }),
    );
    final github = GitHubClient(
      runner: runner,
      owner: 'example-org',
      repo: 'my_app',
    );

    final issue = await github.getIssue(_issueNumber);

    expect(issue['state'], 'OPEN');
    final call = runner.ghCalls.single;
    expect(ghFlagValue(call, '--json'), contains('state'));
  });

  test('getIssue throws GitHubRequestFailure on a non-zero exit', () async {
    final github = buildClient((_) => failedResult(stderr: 'boom'));

    await expectLater(
      github.getIssue(_issueNumber),
      throwsA(isA<GitHubRequestFailure>()),
    );
  });

  test('getPullRequest requests the fields finish needs', () async {
    final runner = ScriptedProcessRunner(
      (_) => jsonResult({
        'number': _prIndex,
        'title': 't',
        'mergeable': 'CONFLICTING',
        'state': 'OPEN',
        'mergeCommit': null,
      }),
    );
    final github = GitHubClient(
      runner: runner,
      owner: 'example-org',
      repo: 'my_app',
    );

    final pr = await github.getPullRequest(_prIndex);

    expect(pr['mergeable'], 'CONFLICTING');
    final call = runner.ghCalls.single;
    expect(ghCommandOf(call), 'pr view');
    expect(call, contains('$_prIndex'));
    expect(ghFlagValue(call, '--json'), contains('mergeCommit'));
  });

  test('addLabel calls gh issue edit --add-label', () async {
    final runner = ScriptedProcessRunner((_) => jsonResult(null));
    final github = GitHubClient(
      runner: runner,
      owner: 'example-org',
      repo: 'my_app',
    );

    await github.addLabel(_issueNumber, 'status/in-progress');

    final call = runner.ghCalls.single;
    expect(ghCommandOf(call), 'issue edit');
    expect(call, contains('$_issueNumber'));
    expect(ghFlagValue(call, '--add-label'), 'status/in-progress');
    expect(ghFlagValue(call, '--repo'), 'example-org/my_app');
  });

  test('addLabel throws GitHubRequestFailure when gh refuses (e.g. the label '
      "doesn't exist)", () async {
    final github = buildClient(
      (_) => failedResult(stderr: "label 'nope' not found"),
    );

    await expectLater(
      github.addLabel(_issueNumber, 'nope'),
      throwsA(isA<GitHubRequestFailure>()),
    );
  });

  test(
    'removeLabelIfPresent removes by name when the label is present',
    () async {
      final calls = <List<String>>[];
      final github = buildClient(
        _issueViewWithOneLabel(calls, 'status/in-progress'),
      );

      await github.removeLabelIfPresent(_issueNumber, 'status/in-progress');

      final editCall = calls.firstWhere((c) => ghCommandOf(c) == 'issue edit');
      expect(ghFlagValue(editCall, '--remove-label'), 'status/in-progress');
    },
  );

  test('removeLabelIfPresent is a no-op when the label is absent', () async {
    final calls = <List<String>>[];
    final github = buildClient((args) {
      calls.add(args);

      return jsonResult({'body': '', 'title': '', 'labels': <dynamic>[]});
    });

    await github.removeLabelIfPresent(_issueNumber, 'status/in-progress');

    expect(calls.any((c) => ghCommandOf(c) == 'issue edit'), isFalse);
  });

  test('mergePullRequest merges with --merge, deletes the branch and uses '
      'commitTitle as --subject', () async {
    final runner = ScriptedProcessRunner((_) => jsonResult(null));
    final github = GitHubClient(
      runner: runner,
      owner: 'example-org',
      repo: 'my_app',
    );

    await github.mergePullRequest(_prIndex, commitTitle: 'feat: thing (#1)');

    final call = runner.ghCalls.single;
    expect(ghCommandOf(call), 'pr merge');
    expect(call, contains('$_prIndex'));
    expect(call, contains('--merge'));
    expect(call, contains('--delete-branch'));
    expect(ghFlagValue(call, '--subject'), 'feat: thing (#1)');
  });

  test('closeIssue calls gh issue close', () async {
    final runner = ScriptedProcessRunner((_) => jsonResult(null));
    final github = GitHubClient(
      runner: runner,
      owner: 'example-org',
      repo: 'my_app',
    );

    await github.closeIssue(_issueNumber);

    final call = runner.ghCalls.single;
    expect(ghCommandOf(call), 'issue close');
    expect(call, contains('$_issueNumber'));
  });

  test(
    'closeAsVerified removes both status labels, comments, then closes',
    () async {
      final calls = <List<String>>[];
      final github = buildClient(
        _issueViewWithOneLabel(calls, 'status/review'),
      );

      await github.closeAsVerified(_issueNumber, 'Merged as abc123.');

      final commands = calls.map(ghCommandOf).toList();
      final editIndices = <int>[
        for (var i = 0; i < commands.length; i++)
          if (commands[i] == 'issue edit') i,
      ];
      final commentIndex = commands.indexOf('issue comment');
      final closeIndex = commands.indexOf('issue close');

      expect(editIndices, hasLength(1), reason: 'only status/review is set');
      expect(editIndices.single, lessThan(commentIndex));
      expect(commentIndex, lessThan(closeIndex));

      final commentCall = calls[commentIndex];
      expect(ghFlagValue(commentCall, '--body'), 'Merged as abc123.');
    },
  );

  test(
    'content-creating calls are spaced apart by the injected throttle',
    () async {
      var now = DateTime(2026);
      final sleeps = <Duration>[];
      final throttle = GitHubThrottle(
        clock: () => now,
        sleeper: (d) async {
          sleeps.add(d);
          now = now.add(d);
        },
      );
      final runner = ScriptedProcessRunner((_) => jsonResult(null));
      final github = GitHubClient(
        runner: runner,
        owner: 'example-org',
        repo: 'my_app',
        throttle: throttle,
      );

      await github.addLabel(_issueNumber, 'status/in-progress');
      await github.addLabel(_issueNumber, 'type/feature');

      expect(sleeps, [const Duration(seconds: 1)]);
    },
  );
}
