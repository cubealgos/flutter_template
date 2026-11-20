// Promotes the checked-out release tag to the production project: applies
// the schema, then deploys every Function and Site. Run it from the main
// checkout at the tag, with the web builds already made (see
// `docs/releasing.md` "Deploying"). Always run `--dry-run` first: a real
// run refuses unless the same commit had a successful dry run.
// Usage: `dart run bin/promote.dart --production [--dry-run]`, from
// `backend/appwrite/tool/`.
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/backend_target.dart';
import 'package:appwrite_tool/src/cli_failure.dart';
import 'package:appwrite_tool/src/cli_options.dart';
import 'package:appwrite_tool/src/dry_run_ledger.dart';
import 'package:appwrite_tool/src/git_inspector.dart';
import 'package:appwrite_tool/src/promoter.dart';
import 'package:appwrite_tool/src/real_promotion_actions.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final options = CliOptions.parse(args);
  if (options.target != BackendTarget.production) {
    stderr.writeln(
      'promote.dart only promotes to production, and only on request: pass '
      '$productionFlag (and --dry-run first).',
    );
    exitCode = 1;

    return;
  }

  await _promote(options);
}

Future<void> _promote(CliOptions options) async {
  var target = 'the production project';
  exitCode = await runReportingFailures(
    target: target,
    operation: options.dryRun ? 'promotion dry run' : 'promotion',
    err: stderr.writeln,
    body: () async {
      final env = options.loadEnv(keyId: 'provisioner');
      // Functions/Sites use the narrower `deployer` key when configured.
      final deployEnv = options.loadEnv(keyId: 'deployer');
      target = '${env.endpoint} (project ${env.projectId})';
      final repoRoot = findRepoRoot(Directory.current);
      final promoter = Promoter(
        git: ProcessGitInspector(repoRoot),
        actions: RealPromotionActions(
          env: env,
          deployEnv: deployEnv,
          repoRoot: repoRoot,
        ),
        ledger: FileDryRunLedger(
          Directory(p.join(Directory.systemTemp.path, 'appwrite_tool_promote')),
          scope: env.projectId,
        ),
        schema: templateSchema,
        log: stdout.writeln,
      );
      stdout.writeln('Production: $target');

      return await promoter.run(dryRun: options.dryRun) ? 0 : 1;
    },
  );
}
