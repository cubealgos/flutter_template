import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/branch_new_command.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/worktree_link_check.dart';

import 'support/git_fixture.dart';
import 'support/scripted_process_runner.dart';

/// Wraps the real system runner but, right after a successful
/// `git worktree add`, rewrites the new worktree's `.git` pointer to an
/// absolute path — simulating `git worktree add --relative-paths` failing
/// to honor the flag, so `BranchNewCommand`'s own verification step (which
/// must never just trust the flag) has something real to catch.
//
// This file is named for the command under test, not for this private fake
// ProcessRunner (the only class declared here).
// ignore: solid_lints/prefer_match_file_name
class _LinkCorruptingRunner implements ProcessRunner {
  _LinkCorruptingRunner(this.repoRoot, this.worktreeName);

  final String repoRoot;
  final String worktreeName;
  static const ProcessRunner _real = SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await _real.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    final isWorktreeAdd =
        executable == 'git' &&
        arguments.length > 1 &&
        arguments.first == 'worktree' &&
        arguments[1] == 'add';
    if (isWorktreeAdd && result.exitCode == 0) {
      final worktreeGitFile = File(
        p.join(repoRoot, '.worktrees', worktreeName, '.git'),
      );
      final absoluteTarget = p.join(
        repoRoot,
        '.git',
        'worktrees',
        worktreeName,
      );
      worktreeGitFile.writeAsStringSync('gitdir: $absoluteTarget\n');
    }

    return result;
  }
}

/// Succeeds every `gh issue edit --add-label` call (and any other `gh`
/// call) — the labels the real repo has are never asked about any more:
/// `GitHubClient.addLabel` calls `gh issue edit` directly and lets `gh`
/// itself refuse an unknown label name.
ScriptedProcessRunner _runnerLabelingIssues() =>
    ScriptedProcessRunner((_) => jsonResult(null));

/// Wraps [inner] (which fakes `gh`) and additionally fakes `fvm use`: it
/// never runs the real `fvm` binary (slow, network-dependent, exactly what
/// tests must avoid), but — unless [createSdkLink] is false — reproduces
/// the one filesystem effect `BranchNewCommand` actually checks for:
/// `.fvm/flutter_sdk/bin/dart` resolving in the worktree `fvm use` ran in.
class _FvmFakingRunner implements ProcessRunner {
  _FvmFakingRunner(this.inner, {this.createSdkLink = true});

  final ScriptedProcessRunner inner;
  final bool createSdkLink;
  final List<List<String>> fvmCalls = <List<String>>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final isFvmUse =
        executable == 'fvm' && arguments.isNotEmpty && arguments.first == 'use';
    if (isFvmUse) {
      fvmCalls.add(arguments);
      if (createSdkLink && workingDirectory != null) {
        File(p.join(workingDirectory, '.fvm', 'flutter_sdk', 'bin', 'dart'))
            .createSync(recursive: true);
      }

      return ProcessResult(0, 0, '', '');
    }

    return await inner.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }
}

void main() {
  final buffer = StringBuffer();
  void out(String m) => buffer.writeln('OUT: $m');
  void err(String m) => buffer.writeln('ERR: $m');

  setUp(buffer.clear);

  final parsingRefusals = <({String name, List<String> args, String fragment})>[
    (
      name: 'unknown family, naming the valid set',
      args: ['feat', '11', 'workflow-tooling'],
      fragment: 'Unknown family "feat"',
    ),
    (
      name: 'invalid slug',
      args: ['feature', '11', 'Not_Kebab'],
      fragment: 'kebab-case',
    ),
    (
      name: 'non-numeric issue number',
      args: ['feature', 'eleven', 'workflow-tooling'],
      fragment: 'positive integer',
    ),
  ];
  for (final refusal in parsingRefusals) {
    test('refuses: ${refusal.name}', () async {
      final command = BranchNewCommand(
        runner: const SystemProcessRunner(),
        out: out,
        err: err,
      );

      final exitCode = await command.run(
        refusal.args,
        repoRoot: Directory.systemTemp.path,
      );

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains(refusal.fragment));
    });
  }

  test('an unknown-family refusal names every valid family', () async {
    final command = BranchNewCommand(
      runner: const SystemProcessRunner(),
      out: out,
      err: err,
    );

    await command.run([
      'feat',
      '11',
      'workflow-tooling',
    ], repoRoot: Directory.systemTemp.path);

    for (final family in <String>[
      'feature',
      'bugfix',
      'chore',
      'documentation',
      'release',
      'hotfix',
    ]) {
      expect(buffer.toString(), contains(family));
    }
  });

  test('refuses the wrong number of arguments', () async {
    final command = BranchNewCommand(
      runner: const SystemProcessRunner(),
      out: out,
      err: err,
    );

    final exitCode = await command.run([
      'feature',
      '11',
    ], repoRoot: Directory.systemTemp.path);

    expect(exitCode, usageExitCode);
  });

  test(
    'refuses when run from inside a worktree, not the main checkout',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      await runGit([
        'worktree',
        'add',
        '--relative-paths',
        '-b',
        'chore/99-throwaway',
        '.worktrees/99',
      ], fixture.mainCheckout.path);

      final command = BranchNewCommand(
        runner: const SystemProcessRunner(),
        out: out,
        err: err,
      );
      final exitCode = await command.run([
        'feature',
        '11',
        'workflow-tooling',
      ], repoRoot: p.join(fixture.mainCheckout.path, '.worktrees', '99'));

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('main checkout'));
    },
  );

  test('refuses when .worktrees/<N> already exists', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    Directory(p.join(fixture.mainCheckout.path, '.worktrees', '11'))
        .createSync(recursive: true);

    final command = BranchNewCommand(
      runner: const SystemProcessRunner(),
      out: out,
      err: err,
    );
    final exitCode = await command.run([
      'feature',
      '11',
      'workflow-tooling',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('already exists'));
  });

  test('refuses when the branch already exists', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    await runGit([
      'branch',
      'feature/11-workflow-tooling',
    ], fixture.mainCheckout.path);

    final command = BranchNewCommand(
      runner: const SystemProcessRunner(),
      out: out,
      err: err,
    );
    final exitCode = await command.run([
      'feature',
      '11',
      'workflow-tooling',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('already exists'));
  });

  test(
    'fails loudly when the worktree link is not genuinely relative',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);

      final command = BranchNewCommand(
        runner: _LinkCorruptingRunner(fixture.mainCheckout.path, '11'),
        out: out,
        err: err,
      );
      final exitCode = await command.run([
        'feature',
        '11',
        'workflow-tooling',
      ], repoRoot: fixture.mainCheckout.path);

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('not relative'));
    },
  );

  test(
    'happy path: creates a relative worktree and labels the issue',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final ghRunner = _runnerLabelingIssues();
      final runner = _FvmFakingRunner(ghRunner);

      final command = BranchNewCommand(runner: runner, out: out, err: err);
      final exitCode = await command.run([
        'feature',
        '11',
        'workflow-tooling',
      ], repoRoot: fixture.mainCheckout.path);

      expect(exitCode, 0, reason: buffer.toString());

      final worktreeDir = Directory(
        p.join(fixture.mainCheckout.path, '.worktrees', '11'),
      );
      expect(worktreeDir.existsSync(), isTrue);

      final branch = await runGit([
        'branch',
        '--show-current',
      ], worktreeDir.path);
      expect((branch.stdout as String).trim(), 'feature/11-workflow-tooling');

      final link = verifyRelativeWorktreeLink(
        repoRoot: fixture.mainCheckout.path,
        worktreeName: '11',
      );
      expect(link.isRelative, isTrue, reason: link.reason);

      final addLabelCalls = ghRunner.ghCalls.where(
        (c) => ghCommandOf(c) == 'issue edit' && c.contains('11'),
      );
      expect(
        addLabelCalls,
        contains(
          predicate<List<String>>(
            (c) => ghFlagValue(c, '--add-label') == 'status/in-progress',
          ),
        ),
      );
      expect(
        addLabelCalls,
        contains(
          predicate<List<String>>(
            (c) => ghFlagValue(c, '--add-label') == 'type/feature',
          ),
        ),
        reason: 'feature branches must also get the type/feature label',
      );
    },
  );

  for (final entry in <String, String>{
    'feature': 'type/feature',
    'bugfix': 'type/bugfix',
    'chore': 'type/chore',
    'documentation': 'type/docs',
  }.entries) {
    test('${entry.key} branches get the ${entry.value} type label', () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final ghRunner = _runnerLabelingIssues();
      final runner = _FvmFakingRunner(ghRunner);

      final command = BranchNewCommand(runner: runner, out: out, err: err);
      final exitCode = await command.run([
        entry.key,
        '11',
        'workflow-tooling',
      ], repoRoot: fixture.mainCheckout.path);

      expect(exitCode, 0, reason: buffer.toString());
      final addLabelCalls = ghRunner.ghCalls.where(
        (c) => ghCommandOf(c) == 'issue edit' && c.contains('11'),
      );
      expect(
        addLabelCalls,
        contains(
          predicate<List<String>>(
            (c) => ghFlagValue(c, '--add-label') == entry.value,
          ),
        ),
      );
    });
  }

  for (final family in <String>['release', 'hotfix']) {
    test(
      '$family branches get no type/* label (none exists on the repo)',
      () async {
        final fixture = await createGitFixture();
        addTearDown(fixture.dispose);
        final ghRunner = _runnerLabelingIssues();
        final runner = _FvmFakingRunner(ghRunner);

        final command = BranchNewCommand(runner: runner, out: out, err: err);
        final exitCode = await command.run([
          family,
          '11',
          'workflow-tooling',
        ], repoRoot: fixture.mainCheckout.path);

        expect(exitCode, 0, reason: buffer.toString());
        final addLabelCalls = ghRunner.ghCalls.where(
          (c) => ghCommandOf(c) == 'issue edit' && c.contains('11'),
        );
        expect(addLabelCalls, hasLength(1), reason: 'status label only');
      },
    );
  }

  test('branches hotfix from production, not development', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final runner = _FvmFakingRunner(_runnerLabelingIssues());

    final command = BranchNewCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([
      'hotfix',
      '22',
      'urgent-fix',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, 0, reason: buffer.toString());
    final worktreeDir = p.join(fixture.mainCheckout.path, '.worktrees', '22');
    final mergeBase = await runGit([
      'merge-base',
      '--is-ancestor',
      'HEAD',
      'origin/production',
    ], worktreeDir);
    expect(mergeBase.exitCode, 0);
  });

  test('pins the new worktree to the .fvmrc Flutter SDK via fvm use', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final runner = _FvmFakingRunner(_runnerLabelingIssues());

    final command = BranchNewCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([
      'feature',
      '11',
      'workflow-tooling',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, 0, reason: buffer.toString());
    expect(runner.fvmCalls.single, [
      'use',
      fixtureFlutterVersion,
      '--skip-pub-get',
      '--force',
    ]);
    final dartBinary = File(
      p.join(
        fixture.mainCheckout.path,
        '.worktrees',
        '11',
        '.fvm',
        'flutter_sdk',
        'bin',
        'dart',
      ),
    );
    expect(dartBinary.existsSync(), isTrue);
  });

  test(
    'fails loudly when fvm use succeeds but the SDK link does not resolve',
    () async {
      final fixture = await createGitFixture();
      addTearDown(fixture.dispose);
      final runner = _FvmFakingRunner(
        _runnerLabelingIssues(),
        createSdkLink: false,
      );

      final command = BranchNewCommand(runner: runner, out: out, err: err);
      final exitCode = await command.run([
        'feature',
        '11',
        'workflow-tooling',
      ], repoRoot: fixture.mainCheckout.path);

      expect(exitCode, isNot(0));
      expect(buffer.toString(), contains('does not resolve'));
      expect(
        buffer.toString(),
        isNot(contains('status/in-progress')),
        reason: 'must refuse before labeling the issue',
      );
    },
  );

  test('refuses when .fvmrc is missing from the main checkout', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    File(p.join(fixture.mainCheckout.path, '.fvmrc')).deleteSync();
    final runner = _FvmFakingRunner(_runnerLabelingIssues());

    final command = BranchNewCommand(runner: runner, out: out, err: err);
    final exitCode = await command.run([
      'feature',
      '11',
      'workflow-tooling',
    ], repoRoot: fixture.mainCheckout.path);

    expect(exitCode, isNot(0));
    expect(buffer.toString(), contains('.fvmrc not found'));
  });
}
