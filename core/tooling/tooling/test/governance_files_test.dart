import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Keeps the root legal/governance files consistent: `NOTICE` and
/// `CLA.md` name the same maintaining entity, `SECURITY.md` points at a
/// private reporting channel, and none of them publishes an e-mail
/// address. These are plain text, not Dart, so a drift between them would
/// otherwise ship silently.
void main() {
  // `dart test` runs with the package root (core/tooling/tooling) as the
  // working directory — same reasoning as
  // `changelog_check_command_test.dart`'s real-repo test, which this
  // resolution is copied from.
  final repoRoot = p.normalize(
    p.join(Directory.current.path, '..', '..', '..'),
  );

  String readRootFile(String name) =>
      File(p.join(repoRoot, name)).readAsStringSync();

  /// Every e-mail address in [text] that is not on the `example.com`
  /// placeholder domain.
  List<String> realEmails(String text) =>
      RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+')
          .allMatches(text)
          .map((m) => m[0] ?? '')
          .where((email) => !email.endsWith('@example.com'))
          .toList();

  /// The maintaining entity named in `NOTICE`'s copyright line.
  String noticeHolder(String notice) {
    final match = RegExp(
      r'^Copyright \d{4} (.+)$',
      multiLine: true,
    ).firstMatch(notice);

    return match?[1]?.trim() ?? '';
  }

  group('root governance files name one maintainer and publish no e-mail '
      'address', () {
    test('NOTICE has a copyright line and no e-mail address', () {
      final notice = readRootFile('NOTICE');
      expect(noticeHolder(notice), isNotEmpty);
      expect(realEmails(notice), isEmpty);
    });

    test('CLA.md names the same Maintainer as NOTICE', () {
      final holder = noticeHolder(readRootFile('NOTICE'));
      final cla = readRootFile('CLA.md');
      expect(cla, contains(holder));
      expect(realEmails(cla), isEmpty);
    });

    test('SECURITY.md points at private vulnerability reporting', () {
      final security = readRootFile('SECURITY.md');
      expect(security, contains('private vulnerability reporting'));
      expect(realEmails(security), isEmpty);
    });

    test('CONTRIBUTING.md publishes no e-mail address', () {
      final contributing = readRootFile('CONTRIBUTING.md');
      expect(realEmails(contributing), isEmpty);
    });
  });
}
