import 'dart:io';

import 'package:appwrite_tool/src/backend_env.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/git_test_helper.dart';

void main() {
  test('loads every value from the environment map', () {
    final env = BackendEnv.load(
      environment: const <String, String>{
        'APPWRITE_ENDPOINT': 'https://fra.cloud.appwrite.io/v1',
        'APPWRITE_PROJECT_ID': 'proj',
        'APPWRITE_API_KEY': 'key',
      },
      // See the "throws" test below for why this is never omitted.
      dotEnvFile: File('/nonexistent/backend_env_test.env.local'),
    );

    expect(env.endpoint, 'https://fra.cloud.appwrite.io/v1');
    expect(env.projectId, 'proj');
    expect(env.apiKey, 'key');
  });

  test('falls back to a .env.local file, stripping quotes and comments', () {
    final tempDir = Directory.systemTemp.createTempSync('backend_env_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final dotEnvFile = File(p.join(tempDir.path, '.env.local'))
      ..writeAsStringSync('''
# a comment, and a blank line follow

APPWRITE_ENDPOINT="https://fra.cloud.appwrite.io/v1"
APPWRITE_PROJECT_ID=proj
APPWRITE_API_KEY='key'
''');

    final env = BackendEnv.load(
      environment: const <String, String>{},
      dotEnvFile: dotEnvFile,
    );

    expect(env.endpoint, 'https://fra.cloud.appwrite.io/v1');
    expect(env.projectId, 'proj');
    expect(env.apiKey, 'key');
  });

  test('an environment variable overrides the same key in the file', () {
    final tempDir = Directory.systemTemp.createTempSync('backend_env_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final dotEnvFile = File(p.join(tempDir.path, '.env.local'))
      ..writeAsStringSync('''
APPWRITE_ENDPOINT=from-file
APPWRITE_PROJECT_ID=proj
APPWRITE_API_KEY=key
''');

    final env = BackendEnv.load(
      environment: const <String, String>{'APPWRITE_ENDPOINT': 'from-env'},
      dotEnvFile: dotEnvFile,
    );

    expect(env.endpoint, 'from-env');
  });

  test(
    "falls back to the main checkout's shared .env.local when run from a "
    "linked worktree - not that worktree's own copy, which has none",
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'backend_env_shared_test',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final mainCheckout = Directory(p.join(tempDir.path, 'main'))
        ..createSync();
      await runGit(['init', '-q', '-b', 'development'], mainCheckout.path);
      File(p.join(mainCheckout.path, 'README.md')).writeAsStringSync('seed\n');
      await commitInGit(mainCheckout.path, 'README.md', 'seed');
      File(
          p.join(
            mainCheckout.path,
            'backend',
            'appwrite',
            'tool',
            '.env.local',
          ),
        )
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1\n'
          'APPWRITE_PROJECT_ID=shared-proj\n'
          'APPWRITE_API_KEY=shared-key\n',
        );

      final worktree = Directory(p.join(tempDir.path, 'wt24'));
      await runGit([
        'worktree',
        'add',
        '--relative-paths',
        '-q',
        worktree.path,
        '-b',
        'bugfix/24-test',
      ], mainCheckout.path);

      final toolDir = Directory(
        p.join(worktree.path, 'backend', 'appwrite', 'tool'),
      )..createSync(recursive: true);

      final env = BackendEnv.load(
        environment: const <String, String>{},
        workingDirectory: toolDir,
      );

      expect(env.projectId, 'shared-proj');
      expect(env.apiKey, 'shared-key');
    },
  );

  test('throws a MissingBackendConfigException naming the missing key', () {
    expect(
      () => BackendEnv.load(
        environment: const <String, String>{
          'APPWRITE_ENDPOINT': 'https://fra.cloud.appwrite.io/v1',
        },
        // A nonexistent file, not omitted: omitting `dotEnvFile` would let
        // this fall back to auto-discovery, which could pick up a real
        // (gitignored) backend/appwrite/tool/.env.local sitting in the repo during local
        // development and mask the missing-key case this test exists to
        // cover.
        dotEnvFile: File('/nonexistent/backend_env_test.env.local'),
      ),
      throwsA(
        isA<MissingBackendConfigException>().having(
          (e) => e.key,
          'key',
          'APPWRITE_PROJECT_ID',
        ),
      ),
    );
  });
}
