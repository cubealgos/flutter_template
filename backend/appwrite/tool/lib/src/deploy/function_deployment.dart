import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/deploy/archiver.dart';
import 'package:appwrite_tool/src/deploy/bundle_stager.dart';
import 'package:appwrite_tool/src/deploy/deployer.dart';
import 'package:appwrite_tool/src/deploy/pubspec_lock.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:path/path.dart' as p;

/// Stages, archives and deploys [function] to the project [env] points at,
/// printing progress; returns whether the build succeeded. Shared by
/// `bin/deploy.dart` and `bin/promote.dart`.
Future<bool> deployFunctionTo({
  required FunctionSchema function,
  required BackendEnv env,
}) async {
  final repoRoot = findRepoRoot(Directory.current);
  final lockfile = PubspecLock.parse(
    File(p.join(repoRoot.path, 'pubspec.lock')).readAsStringSync(),
  );

  stdout.writeln('Staging ${function.id}...');
  final stager = BundleStager(repoRoot: repoRoot, lockfile: lockfile);
  final stagingDir = stager.stage(function);
  stdout
    ..writeln('Staged bundle pubspec.yaml:')
    ..writeln(File(p.join(stagingDir.path, 'pubspec.yaml')).readAsStringSync());

  final archiveFile = File(
    p.join(stagingDir.parent.path, '${function.id}.tar.gz'),
  );
  await createDeploymentArchive(sourceDir: stagingDir, outputFile: archiveFile);
  stdout.writeln('Archived to ${archiveFile.path}.');

  final client = buildClient(env);
  final deployer = Deployer(client);
  stdout.writeln('Uploading and building (this can take a minute)...');
  final result = await deployer.deploy(
    function: function,
    archive: archiveFile,
  );

  stagingDir.deleteSync(recursive: true);
  archiveFile.deleteSync();

  if (!result.succeeded) {
    stderr
      ..writeln(
        'Build ${result.status.value} for deployment '
        '${result.deploymentId}.',
      )
      ..writeln(result.buildLogs);

    return false;
  }

  stdout.writeln('Deployed and activated: ${result.deploymentId}.');

  return true;
}
