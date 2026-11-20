// The scoped server API keys, declared in `backend/appwrite/schema`
// (`templateSchema.apiKeys`). `dart_appwrite` 29.0.0 cannot create project
// keys (see `ApiKeySchema`), so this prints the one-time creation checklist
// and, with `--audit`, compares the declaration with the project's real
// keys (the key used for `--audit` needs the `keys.read` scope; use a
// short-lived one, it is not in any declared key on purpose).
// Usage: `dart run bin/api_keys.dart [--audit] [--production]`.
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/api_key_audit.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/backend_target.dart';
import 'package:appwrite_tool/src/cli_failure.dart';
import 'package:appwrite_tool/src/dart_appwrite_api_keys_gateway.dart';

Future<void> main(List<String> args) async {
  final production = args.contains(productionFlag);
  final target = production ? BackendTarget.production : BackendTarget.dev;
  final BackendEnv env;
  try {
    env = BackendEnv.load(target: target, allowProduction: production);
  } on MissingBackendConfigException catch (e) {
    stderr.writeln(e);
    exitCode = 1;

    return;
  } on ProductionNotConfirmedException catch (e) {
    stderr.writeln(e);
    exitCode = 1;

    return;
  }

  if (args.contains('--audit')) {
    exitCode = await runReportingFailures(
      target: '${env.endpoint} (project ${env.projectId})',
      operation: 'API key audit',
      err: stderr.writeln,
      body: () => _audit(env),
    );

    return;
  }

  stdout
    ..writeln(
      'Create each key once (needs `appwrite login`; secrets go straight '
      'into the env file):',
    )
    ..writeAll(
      apiKeyChecklist(
        templateSchema.apiKeys,
        projectId: env.projectId,
        envFile: 'backend/appwrite/tool/${target.envFileName}',
        variableFor: BackendEnv.apiKeyVariable,
      ),
      '\n',
    )
    ..writeln();
}

Future<int> _audit(BackendEnv env) async {
  final problems = auditApiKeys(
    templateSchema.apiKeys,
    await DartAppwriteApiKeysGateway(buildClient(env)).listKeys(),
  );
  if (problems.isEmpty) {
    stdout.writeln('API keys match the declaration.');

    return 0;
  }
  problems.forEach(stderr.writeln);

  return 1;
}
