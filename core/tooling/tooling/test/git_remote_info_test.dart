import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/git_remote_info.dart';

typedef _Case = ({String url, String host, String owner, String repo});

const List<_Case> _cases = <_Case>[
  (
    url: 'https://github.com/example-org/my_app.git',
    host: 'github.com',
    owner: 'example-org',
    repo: 'my_app',
  ),
  (
    url: 'https://github.com/example-org/my_app',
    host: 'github.com',
    owner: 'example-org',
    repo: 'my_app',
  ),
  (
    url: 'git@github.com:example-org/my_app.git',
    host: 'github.com',
    owner: 'example-org',
    repo: 'my_app',
  ),
  (
    url: '/tmp/fixture/example-org/my_app.git',
    host: 'local',
    owner: 'example-org',
    repo: 'my_app',
  ),
];

void main() {
  for (final testCase in _cases) {
    test('parses ${testCase.url}', () {
      final info = parseGitRemoteUrl(testCase.url);
      expect(info.host, testCase.host);
      expect(info.owner, testCase.owner);
      expect(info.repo, testCase.repo);
    });
  }

  test('refuses a URL matching no recognized shape', () {
    expect(
      () => parseGitRemoteUrl('not-a-url'),
      throwsA(isA<CommandFailure>()),
    );
  });
}
