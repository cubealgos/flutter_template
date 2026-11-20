import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/archiver.dart';
import 'package:appwrite_tool/src/deploy/bundle_stager.dart';
import 'package:appwrite_tool/src/deploy/deployer.dart';
import 'package:appwrite_tool/src/deploy/pubspec_lock.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:path/path.dart' as p;

/// Deploys the one `api` router Function for real through [adminClient],
/// mirroring `backend/appwrite/tool`'s `bin/deploy.dart`: stage, vendor,
/// archive, upload and wait for the build. Throws a [StateError] with the
/// build logs if it fails. Shared by this package's integration suites,
/// which can't assume another suite already deployed it.
Future<void> deployApi(server.Client adminClient) =>
    deployFunction(adminClient, 'api');

/// Deploys the Function [functionId] (`api` or `hooks`) the same way.
Future<void> deployFunction(
  server.Client adminClient,
  String functionId,
) async {
  final repoRoot = findRepoRoot(Directory.current);
  final lockfile = PubspecLock.parse(
    File(p.join(repoRoot.path, 'pubspec.lock')).readAsStringSync(),
  );
  final function = templateSchema.functions.singleWhere(
    (f) => f.id == functionId,
  );
  final stagingDir = BundleStager(
    repoRoot: repoRoot,
    lockfile: lockfile,
  ).stage(function);
  final archiveFile = File(
    p.join(
      stagingDir.parent.path,
      '${functionId}_backend_appwrite_integration.tar.gz',
    ),
  );

  try {
    await createDeploymentArchive(
      sourceDir: stagingDir,
      outputFile: archiveFile,
    );
    final result = await Deployer(adminClient)
        .deploy(function: function, archive: archiveFile);
    if (!result.succeeded) {
      throw StateError('$functionId build failed: ${result.buildLogs}');
    }
  } finally {
    if (stagingDir.existsSync()) stagingDir.deleteSync(recursive: true);
    if (archiveFile.existsSync()) archiveFile.deleteSync();
  }
}
