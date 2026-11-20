// Deploys one prebuilt static build to an Appwrite Site. Building is the
// caller's job (the tool never builds): see each `SiteSchema.buildCommand`
// in `backend/appwrite/schema`, or `docs/releasing.md` "Deploying".
// Usage: `dart run bin/deploy_site.dart <site-id> [--production]
// [--dry-run]`, from `backend/appwrite/tool/`.
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/backend_target.dart';
import 'package:appwrite_tool/src/cli_failure.dart';
import 'package:appwrite_tool/src/cli_options.dart';
import 'package:appwrite_tool/src/deploy/dart_appwrite_sites_gateway.dart';
import 'package:appwrite_tool/src/deploy/site_deployer.dart';
import 'package:appwrite_tool/src/repo_root.dart';

Future<void> main(List<String> args) async {
  final options = CliOptions.parse(args);
  final known = templateSchema.sites.map((s) => s.id).join(', ');
  if (options.positional.length != 1) {
    stderr.writeln(
      'Usage: dart run bin/deploy_site.dart <site-id> '
      '[$productionFlag] [--dry-run]  (sites: $known)',
    );
    exitCode = 1;

    return;
  }
  final site = templateSchema.sites
      .where((s) => s.id == options.positional.single)
      .firstOrNull;
  if (site == null) {
    stderr.writeln(
      'Unknown site "${options.positional.single}". Declared: $known.',
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
  stdout.writeln('Target $target.');
  exitCode = await runReportingFailures(
    target: target,
    operation: options.dryRun ? 'site dry run' : 'site deploy',
    err: stderr.writeln,
    body: () => _deploy(site, env, dryRun: options.dryRun),
  );
}

Future<int> _deploy(
  SiteSchema site,
  BackendEnv env, {
  required bool dryRun,
}) async {
  final repoRoot = findRepoRoot(Directory.current);
  final deployer = SiteDeployer(DartAppwriteSitesGateway(buildClient(env)));
  final scratch = Directory.systemTemp.createTempSync('deploy_site');
  try {
    final result = dryRun
        ? await deployer.dryRun(site, repoRoot)
        : await deployer.deploy(site, repoRoot, scratch: scratch);
    (result.succeeded ? stdout : stderr).writeln(
      '${site.id}: ${result.summary}',
    );

    return result.succeeded ? 0 : 1;
  } finally {
    scratch.deleteSync(recursive: true);
  }
}
