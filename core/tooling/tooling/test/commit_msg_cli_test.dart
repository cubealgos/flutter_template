@Tags(['cli'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises `bin/commit_msg.dart` as an actual subprocess, the way the git
/// hook in `tool/hooks/commit-msg` invokes it.
void main() {
  // Assigned in setUp/read in tests/cleaned in tearDown — the standard
  // package:test fixture-per-test pattern; there's no meaningful non-null
  // default to construct it with instead.
  // ignore: solid_lints/avoid_late_keyword
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'tooling_commit_msg_cli_test_',
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<ProcessResult> runCommitMsg(String message) {
    final file = File(p.join(tempDir.path, 'COMMIT_EDITMSG'))
      ..writeAsStringSync(message);

    return Process.run('dart', [
      'run',
      'bin/commit_msg.dart',
      file.path,
    ], workingDirectory: Directory.current.path);
  }

  test('accepts a conforming commit message', () async {
    final result = await runCommitMsg(
      'feat(tooling): add commit_msg hook (#1)\n',
    );
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('rejects a non-conforming commit message', () async {
    final result = await runCommitMsg('wip\n');
    expect(result.exitCode, 1);
    expect(result.stderr, contains('rejected'));
  });

  test('rejects a missing commit message file', () async {
    final result = await Process.run('dart', [
      'run',
      'bin/commit_msg.dart',
      p.join(tempDir.path, 'does_not_exist'),
    ], workingDirectory: Directory.current.path);
    expect(result.exitCode, 1);
  });
}
