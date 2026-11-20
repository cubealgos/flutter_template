import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/rename_leftover_check.dart';

void main() {
  // Assigned in setUp/read in tests/cleaned in tearDown — the standard
  // package:test fixture-per-test pattern; there's no meaningful non-null
  // default to construct it with instead (see
  // commit_msg_cli_test.dart's identical `tempDir`).
  // ignore: solid_lints/avoid_late_keyword
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('leftover_check_');
  });
  tearDown(() {
    if (repoRoot.existsSync()) repoRoot.deleteSync(recursive: true);
  });

  void write(String relativePath, String content) {
    File(p.join(repoRoot.path, relativePath))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  test('finds a case-insensitive hit and reports its path and line', () {
    write('README.md', 'line one\nFLUTTER_TEMPLATE lives here\n');

    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot.path,
      searchTerms: ['flutter_template'],
      isAllowListed: (_) => false,
    );

    const matchingLine = 2; // "FLUTTER_TEMPLATE lives here" is the 2nd line.
    expect(leftovers, hasLength(1));
    expect(leftovers.single.relativePath, 'README.md');
    expect(leftovers.single.line, matchingLine);
    expect(leftovers.single.excerpt, contains('FLUTTER_TEMPLATE'));
  });

  test('skips paths the allow-list predicate accepts', () {
    write('core/tooling/tooling/test/fixture.dart', 'flutter_template\n');

    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot.path,
      searchTerms: ['flutter_template'],
      isAllowListed: (path) => path.startsWith('core/tooling/tooling/test/'),
    );

    expect(leftovers, isEmpty);
  });

  test('never descends into excluded directories (.git, .dart_tool, ...)', () {
    write('.git/COMMIT_EDITMSG', 'flutter_template\n');
    write('.dart_tool/package_config.json', 'flutter_template\n');
    write('.fvm/flutter_sdk/version', 'flutter_template\n');

    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot.path,
      searchTerms: ['flutter_template'],
      isAllowListed: (_) => false,
    );

    expect(leftovers, isEmpty);
  });

  test('skips binary extensions instead of throwing on non-UTF-8 bytes', () {
    File(p.join(repoRoot.path, 'icon.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([0xff, 0xd8, 0x00, 0xff]);

    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot.path,
      searchTerms: ['flutter_template'],
      isAllowListed: (_) => false,
    );

    expect(leftovers, isEmpty);
  });

  test('matches any of several search terms', () {
    write('a.txt', 'the old org com.example\n');
    write('b.txt', 'nothing to see\n');

    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot.path,
      searchTerms: ['flutter_template', 'com.example'],
      isAllowListed: (_) => false,
    );

    expect(leftovers, hasLength(1));
    expect(leftovers.single.relativePath, 'a.txt');
  });

  test('empty search terms find nothing', () {
    write('a.txt', 'flutter_template\n');

    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot.path,
      searchTerms: const [],
      isAllowListed: (_) => false,
    );

    expect(leftovers, isEmpty);
  });

  test('allow-lists the historical design record docs, not rewritten by '
      'rename', () {
    expect(renameLeftoverAllowList, contains('docs/design/spec.md'));
    expect(
      renameLeftoverAllowList,
      contains('docs/design/mockups/canvas.json'),
    );
  });
}
