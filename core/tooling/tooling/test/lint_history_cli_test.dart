@Tags(['cli'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises `bin/lint_history.dart` against a throwaway git repository with
/// a mix of conforming and offending commits, and against a baseline file
/// that exempts one of the offenders.
void main() {
  // Assigned in setUp/read throughout the tests/cleaned in tearDown — the
  // standard package:test fixture-per-test pattern; there's no meaningful
  // non-null default to construct it with instead.
  // ignore: solid_lints/avoid_late_keyword
  late Directory repo;
  final toolingDir = Directory.current.path;

  Future<void> git(List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: repo.path);
    expect(
      result.exitCode,
      0,
      reason: 'git ${args.join(' ')} failed: ${result.stderr}',
    );
  }

  Future<void> commit(String subject) async {
    File(p.join(repo.path, 'f.txt')).writeAsStringSync(
      '${DateTime.now().microsecondsSinceEpoch}\n',
      mode: FileMode.append,
    );
    await git(['add', 'f.txt']);
    await git([
      '-c',
      'user.name=Test',
      '-c',
      'user.email=test@example.com',
      'commit',
      '-m',
      subject,
    ]);
  }

  setUp(() async {
    repo = Directory.systemTemp.createTempSync(
      'tooling_lint_history_cli_test_',
    );
    await git(['init', '-q', '-b', 'main']);
  });

  tearDown(() {
    if (repo.existsSync()) repo.deleteSync(recursive: true);
  });

  Future<ProcessResult> runLintHistory({String? baseline}) {
    final args = ['run', 'bin/lint_history.dart', '--repo', repo.path];
    if (baseline != null) args.addAll(['--baseline', baseline]);

    return Process.run('dart', args, workingDirectory: toolingDir);
  }

  test('passes when every commit subject conforms', () async {
    await commit('chore(repo): initialize repository (#1)');
    await commit('feat(tooling): add lint_history (#1)');

    final result = await runLintHistory();
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('fails and lists an offending commit', () async {
    await commit('chore(repo): initialize repository (#1)');
    await commit('wip');

    final result = await runLintHistory();
    expect(result.exitCode, 1);
    expect(result.stderr, contains('wip'));
  });

  test('a baseline-listed SHA is exempt', () async {
    await commit('chore(repo): initialize repository (#1)');
    await commit('wip');
    final offendingSha = (await Process.run('git', [
      'rev-parse',
      'HEAD',
    ], workingDirectory: repo.path)).stdout.toString().trim();

    final baseline = File(p.join(repo.path, 'baseline.txt'))
      ..writeAsStringSync('# baseline\n$offendingSha\n');

    final result = await runLintHistory(baseline: baseline.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
