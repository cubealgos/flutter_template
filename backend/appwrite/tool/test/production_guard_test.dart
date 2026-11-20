import 'dart:io';

import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/backend_target.dart';
import 'package:appwrite_tool/src/cli_options.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/temp_dir.dart';

String _envFile(String project, {String key = 'k'}) =>
    'APPWRITE_ENDPOINT=https://e/v1\nAPPWRITE_PROJECT_ID=$project\n'
    'APPWRITE_API_KEY=$key\n';

void main() {
  test('production without the flag is refused, even with the file', () {
    final dir = tempDir('production_guard');
    File(p.join(dir.path, '.env.production.local'))
        .writeAsStringSync(_envFile('prod'));

    expect(
      () => BackendEnv.load(
        target: BackendTarget.production,
        workingDirectory: dir,
      ),
      throwsA(isA<ProductionNotConfirmedException>()),
    );
  });

  test('production with the flag reads only its own file', () {
    final dir = tempDir('production_guard');
    File(p.join(dir.path, '.env.production.local'))
        .writeAsStringSync(_envFile('prod'));

    final env = BackendEnv.load(
      target: BackendTarget.production,
      allowProduction: true,
      workingDirectory: dir,
      // A dev variable must not leak into a production run.
      environment: const <String, String>{'APPWRITE_PROJECT_ID': 'dev'},
    );

    expect(env.projectId, 'prod');
  });

  test('a dev run whose project is the production project is refused', () {
    final dir = tempDir('production_guard');
    File(p.join(dir.path, '.env.production.local'))
        .writeAsStringSync(_envFile('prod'));

    expect(
      () => BackendEnv.load(
        workingDirectory: dir,
        environment: const <String, String>{
          'APPWRITE_ENDPOINT': 'https://e/v1',
          'APPWRITE_PROJECT_ID': 'prod',
          'APPWRITE_API_KEY': 'k',
        },
      ),
      throwsA(
        isA<ProductionNotConfirmedException>().having(
          (e) => e.viaDevConfig,
          'viaDevConfig',
          isTrue,
        ),
      ),
    );
  });

  test('a dev run on a different project is fine', () {
    final dir = tempDir('production_guard');
    File(p.join(dir.path, '.env.production.local'))
        .writeAsStringSync(_envFile('prod'));
    File(p.join(dir.path, '.env.local')).writeAsStringSync(_envFile('dev'));

    expect(
      BackendEnv.load(workingDirectory: dir, environment: const {}).projectId,
      'dev',
    );
  });

  test('a scoped key wins over the shared one, which stays the fallback', () {
    final dir = tempDir('production_guard');
    final file = File(p.join(dir.path, '.env.local'))
      ..writeAsStringSync(
        '${_envFile('dev', key: 'broad')}'
        'APPWRITE_API_KEY_DEPLOYER=narrow\n',
      );

    BackendEnv load(String? keyId) => BackendEnv.load(
      dotEnvFile: file,
      environment: const <String, String>{},
      keyId: keyId,
    );

    expect(load('deployer').apiKey, 'narrow');
    expect(load('provisioner').apiKey, 'broad');
    expect(load(null).apiKey, 'broad');
    expect(
      BackendEnv.apiKeyVariable('review-demo-seeder'),
      'APPWRITE_API_KEY_REVIEW_DEMO_SEEDER',
    );
  });

  test('--production and --dry-run are parsed and stripped', () {
    final options = CliOptions.parse(<String>[
      'app',
      '--production',
      '--dry-run',
    ]);

    expect(options.target, BackendTarget.production);
    expect(options.dryRun, isTrue);
    expect(options.positional, <String>['app']);
    expect(CliOptions.parse(<String>['app']).target, BackendTarget.dev);
  });
}
