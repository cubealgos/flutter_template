import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_admin.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/deploy/dart_appwrite_sites_gateway.dart';
import 'package:appwrite_tool/src/deploy/function_deployment.dart';
import 'package:appwrite_tool/src/deploy/site_deployer.dart';
import 'package:appwrite_tool/src/dry_run_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/promoter.dart';
import 'package:appwrite_tool/src/provisioner.dart';

/// The production-wired [PromotionActions]: [env] provisions, [deployEnv]
/// (the narrower `deployer` key when configured) deploys Functions and Sites.
class RealPromotionActions implements PromotionActions {
  /// Creates the actions.
  RealPromotionActions({
    required this.env,
    required this.deployEnv,
    required this.repoRoot,
  });

  /// Used for provisioning.
  final BackendEnv env;

  /// Used for Function and Site deployments.
  final BackendEnv deployEnv;

  /// The checkout holding the build outputs.
  final Directory repoRoot;

  @override
  Future<List<String>> provision({required bool dryRun}) async {
    final real = DartAppwriteAdmin(buildClient(env));
    // ignore: omit_local_variable_types, the two branches need the interface.
    final AppwriteAdmin admin = dryRun ? DryRunAdmin(real) : real;
    final report = await Provisioner(
      admin: admin,
      schema: templateSchema,
      mail: MailSettings.fromValues(env.mail),
    ).run();

    return report.changes;
  }

  @override
  Future<bool> deployFunction(FunctionSchema function, {required bool dryRun}) {
    if (dryRun) {
      stdout.writeln(
        '  would stage, build and deploy ${function.path} (not run in a '
        'dry run)',
      );

      return Future<bool>.value(true);
    }

    return deployFunctionTo(function: function, env: deployEnv);
  }

  @override
  Future<bool> deploySite(SiteSchema site, {required bool dryRun}) async {
    final deployer = SiteDeployer(
      DartAppwriteSitesGateway(buildClient(deployEnv)),
    );
    final scratch = Directory.systemTemp.createTempSync('promote_site');
    try {
      final result = dryRun
          ? await deployer.dryRun(site, repoRoot)
          : await deployer.deploy(site, repoRoot, scratch: scratch);
      stdout.writeln('  ${result.summary}');

      return result.succeeded;
    } finally {
      scratch.deleteSync(recursive: true);
    }
  }
}
