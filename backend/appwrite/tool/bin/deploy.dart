// Deploys one Appwrite Function: stages it (function source + every path
// dependency it transitively needs, vendored and pinned — see
// `lib/src/deploy/bundle_stager.dart`), tar.gz's the result, uploads it as
// a new deployment, and polls until the build finishes, printing the build
// log on failure. Usage: `dart run bin/deploy.dart <function-id>
// [--production]`, from `backend/appwrite/tool/`. `--production` targets
// the production project (`.env.production.local`); without it the dev
// project (`.env.local`) is used and a dev config that points at
// production is refused. See `backend/appwrite/README.md`.
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/backend_target.dart';
import 'package:appwrite_tool/src/cli_failure.dart';
import 'package:appwrite_tool/src/cli_options.dart';
import 'package:appwrite_tool/src/deploy/function_deployment.dart';

Future<void> main(List<String> args) async {
  final options = CliOptions.parse(args);
  if (options.positional.length != 1) {
    stderr.writeln(
      'Usage: dart run bin/deploy.dart <function-id> [$productionFlag]',
    );
    exitCode = 1;

    return;
  }

  final function = _findFunction(options.positional.single);
  if (function == null) {
    final known = templateSchema.functions.map((f) => f.id).join(', ');
    stderr.writeln(
      'Unknown function "${options.positional.single}". Declared in the '
      'schema: $known.',
    );
    exitCode = 1;

    return;
  }

  final BackendEnv env;
  try {
    env = options.loadEnv(keyId: 'deployer');
  } on MissingBackendConfigException catch (e) {
    stderr.writeln(e);
    exitCode = 1;

    return;
  } on ProductionNotConfirmedException catch (e) {
    stderr.writeln(e);
    exitCode = 1;

    return;
  }

  final target = '${env.endpoint} (project ${env.projectId})';
  stdout.writeln('Deploying to $target.');
  exitCode = await runReportingFailures(
    target: target,
    operation: 'function deploy',
    err: stderr.writeln,
    body: () async =>
        await deployFunctionTo(function: function, env: env) ? 0 : 1,
  );
}

FunctionSchema? _findFunction(String functionId) {
  for (final function in templateSchema.functions) {
    if (function.id == functionId) return function;
  }

  return null;
}
