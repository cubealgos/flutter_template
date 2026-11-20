// Provisions the template's Appwrite backend from
// `package:appwrite_schema`'s `templateSchema` — idempotent: run it again
// after nothing changed and it prints "up to date" without making any
// create/update calls. See `backend/appwrite/README.md` for the required API key
// scopes and how to point this at a running instance (env vars or
// `backend/appwrite/tool/.env.local`). Usage: `dart run bin/provision.dart
// [--production] [--dry-run]` — `--production` targets the production
// project (`.env.production.local`), `--dry-run` only reports the changes.
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_admin.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/cli_failure.dart';
import 'package:appwrite_tool/src/cli_options.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/dry_run_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/provisioner.dart';

Future<void> main(List<String> args) async {
  final options = CliOptions.parse(args);
  final BackendEnv env;
  try {
    env = options.loadEnv(keyId: 'provisioner');
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
  exitCode = await runReportingFailures(
    target: target,
    operation: options.dryRun ? 'provision dry run' : 'provision',
    err: stderr.writeln,
    body: () => _provision(env, target, dryRun: options.dryRun),
  );
}

Future<int> _provision(
  BackendEnv env,
  String target, {
  required bool dryRun,
}) async {
  final real = DartAppwriteAdmin(buildClient(env));
  // ignore: omit_local_variable_types, the two branches need the interface.
  final AppwriteAdmin admin = dryRun ? DryRunAdmin(real) : real;
  final provisioner = Provisioner(
    admin: admin,
    schema: templateSchema,
    mail: MailSettings.fromValues(env.mail),
  );

  stdout.writeln(
    '${dryRun ? 'DRY RUN, nothing is changed: ' : ''}Provisioning $target...',
  );
  final report = await provisioner.run();

  report.notes.map((n) => 'Note: $n').forEach(stdout.writeln);
  if (report.isNoOp) {
    stdout.writeln('Up to date - nothing to do.');

    return 0;
  }

  stdout.writeln(
    '${dryRun ? 'Would apply' : 'Applied'} '
    '${report.changes.length} change(s):',
  );
  report.changes.map((c) => '  - $c').forEach(stdout.writeln);

  return 0;
}
