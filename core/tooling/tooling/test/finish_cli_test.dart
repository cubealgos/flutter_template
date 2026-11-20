@Tags(['cli'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/git_fixture.dart';

/// Exercises `bin/finish.dart` as an actual subprocess (not the in-process
/// `FinishCommand` the way `finish_command_test.dart` does) on two refusal
/// paths, so a regression in `bin/finish.dart`'s own `exit(exitCode)` plumbing
/// — as opposed to `FinishCommand.run`'s returned value, which
/// `finish_command_test.dart` already covers — would be caught. A past bug:
/// `finish` printed a verification-check failure and still exited 0.
///
/// Both tests here are deliberately "cheap" refusals that stop before the
/// verification suite (a real `fvm dart run melos run <script>` per check)
/// would run: the first needs no fake `gh` at all, the second needs only
/// two canned GitHub responses. The verification-suite-failure exit code
/// itself is covered in-process (network-free) by
/// `finish_command_test.dart`'s "a failing verification check..." test,
/// which asserts on `FinishCommand.run`'s returned exit code —
/// `bin/finish.dart` does nothing with it but `exit(exitCode)`.
void main() {
  // Assigned in setUp/read in tests/cleaned in tearDown — the standard
  // package:test fixture-per-test pattern; there's no meaningful non-null
  // default to construct it with instead.
  // ignore: solid_lints/avoid_late_keyword
  late Directory fakeBin;

  final binPath = p.join(Directory.current.path, 'bin', 'finish.dart');

  setUp(() {
    fakeBin = Directory.systemTemp.createTempSync('tooling_finish_cli_fake_');
  });

  tearDown(() {
    if (fakeBin.existsSync()) fakeBin.deleteSync(recursive: true);
  });

  /// Writes an executable fake `gh` to [fakeBin] that answers `pr list`
  /// and `issue view` with [prBody] and [issueBody] respectively (both
  /// already-encoded JSON), and every other call with `null` — enough for
  /// the refusal paths above `finish`'s merge step, never enough to reach
  /// it.
  void writeFakeGh({required String prBody, required String issueBody}) {
    final script = File(p.join(fakeBin.path, 'gh'))
      ..createSync()
      ..writeAsStringSync('''
#!/usr/bin/env bash
# Fake gh CLI: <cmd> <action> ... [--json ...] [--repo ...]
case "\$1 \$2" in
  "pr list") printf '%s' '$prBody' ;;
  "issue view") printf '%s' '$issueBody' ;;
  *) printf 'null' ;;
esac
exit 0
''');
    Process.runSync('chmod', ['+x', script.path]);
  }

  Future<ProcessResult> runFinishBin(
    List<String> args, {
    required String workingDirectory,
  }) => Process.run(
    'dart',
    ['run', binPath, ...args],
    workingDirectory: workingDirectory,
    environment: {'PATH': '${fakeBin.path}:${Platform.environment['PATH']}'},
  );

  test('refuses (non-zero exit) when run from a linked worktree, not the '
      'main checkout', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);
    final main = fixture.mainCheckout.path;

    await runGit([
      'worktree',
      'add',
      '--relative-paths',
      '-b',
      'feature/1-add-thing',
      '.worktrees/1',
      'origin/development',
    ], main);
    final worktreeDir = p.join(main, '.worktrees', '1');

    final result = await runFinishBin(['1'], workingDirectory: worktreeDir);

    expect(
      result.exitCode,
      isNot(0),
      reason: '${result.stdout}\n${result.stderr}',
    );
    expect(result.stderr, contains('main checkout'));
  });

  test('refuses (non-zero exit) via a real subprocess when acceptance '
      'criteria are unchecked', () async {
    final fixture = await createGitFixture();
    addTearDown(fixture.dispose);

    writeFakeGh(
      prBody: jsonEncode([
        {
          'number': 5,
          'title': 'feat(app): add thing (#1)',
          'headRefName': 'feature/1-add-thing',
          'headRefOid': 'deadbeef',
          'baseRefName': 'development',
          'mergeable': 'MERGEABLE',
        },
      ]),
      issueBody: jsonEncode({
        'body': '## Acceptance criteria\n- [ ] first thing\n',
        'labels': <dynamic>[],
        'title': 't',
      }),
    );

    final result = await runFinishBin([
      '1',
    ], workingDirectory: fixture.mainCheckout.path);

    expect(
      result.exitCode,
      isNot(0),
      reason: '${result.stdout}\n${result.stderr}',
    );
    expect(result.stderr, contains('unchecked acceptance criteria'));
    expect(result.stderr, contains('first thing'));
  });
}
