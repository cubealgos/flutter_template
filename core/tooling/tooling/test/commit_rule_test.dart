import 'package:test/test.dart';
import 'package:tooling/src/commit_rule.dart';

void main() {
  group('validateCommitSubject: valid subjects', () {
    for (final subject in <String>[
      'feat(auth): add AuthService (#4)',
      'fix(ui): correct button padding (#12)',
      'docs(readme): explain workspace layout (#1)',
      'chore(repo): initialize repository (#1)',
      'refactor(tooling): simplify map generator (#7)',
      'feat(auth)!: switch to OTP-only sign-in (#9)',
      'build(deps): bump melos to 8.9.0 (#3)',
      'chore(repo.tool): tidy hooks (#2)',
      'feat(tooling_v2): support nested scopes (#5)',
      'merge(repo): development into feature/1-x (#1)',
      'merge(tooling): feature/7-map-gen into development (#7)',
      'release(app): 1.2.0 (#9)',
      'release(tooling): 0.1.0 (#3)',
    ]) {
      test('accepts "$subject"', () {
        expect(isValidCommitSubject(subject), isTrue);
        expect(validateCommitSubject(subject), isNull);
      });
    }
  });

  group('validateCommitSubject: invalid subjects', () {
    <String, String>{
      'wip': 'plain text',
      'feat: add AuthService (#4)': 'missing scope',
      'feat(auth): add AuthService': 'missing issue reference',
      'feat(auth): add AuthService #4': 'issue reference not parenthesized',
      'feature(auth): add AuthService (#4)': 'bad type',
      'feat(Auth): add AuthService (#4)': 'uppercase scope',
      'feat(): add AuthService (#4)': 'empty scope',
      'feat(auth) add AuthService (#4)': 'missing colon',
      'feat(auth):add AuthService (#4)': 'missing space after colon',
      'fixup! feat(auth): add AuthService (#4)': 'fixup! prefix',
      'squash! feat(auth): add AuthService (#4)': 'squash! prefix',
      'merge: development into feature/1-x (#1)': 'merge missing scope',
      'merge(repo): development into feature/1-x': 'merge missing issue ref',
      'release: 1.2.0 (#9)': 'release missing scope',
      'release(app): 1.2.0': 'release missing issue reference',
      '': 'empty subject',
    }.forEach((subject, reason) {
      test('rejects "$subject" ($reason)', () {
        expect(isValidCommitSubject(subject), isFalse);
        expect(validateCommitSubject(subject), isNotNull);
      });
    });
  });

  test('commitTypes lists exactly the allowed Conventional Commits types', () {
    expect(commitTypes, <String>[
      'feat',
      'fix',
      'docs',
      'style',
      'refactor',
      'perf',
      'test',
      'build',
      'ci',
      'chore',
      'revert',
      'merge',
      'release',
    ]);
  });
}
