import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart' as enums;

/// How long [Deployer.deploy] polls before giving up on a build that never
/// finishes.
const int buildTimeoutMinutes = 5;

/// How long [Deployer.deploy] waits between polls of the deployment's
/// build status.
const int pollIntervalSeconds = 3;

/// Every [enums.DeploymentStatus] that means the build has stopped running
/// — successfully or not.
const Set<enums.DeploymentStatus> finishedDeploymentStatuses =
    <enums.DeploymentStatus>{
      enums.DeploymentStatus.ready,
      enums.DeploymentStatus.failed,
      enums.DeploymentStatus.canceled,
    };

/// Uploads a staged function bundle (see `BundleStager`,
/// `createDeploymentArchive`) and polls until the build finishes,
/// activating it on success.
class Deployer {
  /// Creates a deployer backed by [client].
  Deployer(Client client) : _functions = Functions(client);

  final Functions _functions;

  /// Uploads [archive] as a new deployment of [function] and waits for the
  /// build to finish.
  Future<DeploymentResult> deploy({
    required FunctionSchema function,
    required File archive,
  }) async {
    final deployment = await _functions.createDeployment(
      functionId: function.id,
      code: InputFile.fromPath(path: archive.path),
      activate: true,
      entrypoint: function.entrypoint,
      commands: function.commands,
    );

    return await _pollUntilDone(
      functionId: function.id,
      deploymentId: deployment.$id,
    );
  }

  Future<DeploymentResult> _pollUntilDone({
    required String functionId,
    required String deploymentId,
  }) async {
    const timeout = Duration(minutes: buildTimeoutMinutes);
    const pollInterval = Duration(seconds: pollIntervalSeconds);
    final deadline = DateTime.now().add(timeout);

    while (true) {
      final deployment = await _functions.getDeployment(
        functionId: functionId,
        deploymentId: deploymentId,
      );
      if (finishedDeploymentStatuses.contains(deployment.status)) {
        return DeploymentResult(
          deploymentId: deployment.$id,
          status: deployment.status,
          buildLogs: deployment.buildLogs,
        );
      }
      if (DateTime.now().isAfter(deadline)) {
        return DeploymentResult(
          deploymentId: deployment.$id,
          status: deployment.status,
          buildLogs:
              'Timed out waiting for the build to finish (still '
              '"${deployment.status.value}" after $buildTimeoutMinutes '
              'minutes).',
        );
      }
      await Future<void>.delayed(pollInterval);
    }
  }
}

/// The outcome of a [Deployer.deploy] call.
class DeploymentResult {
  /// Creates a result.
  const DeploymentResult({
    required this.deploymentId,
    required this.status,
    required this.buildLogs,
  });

  /// The created deployment's ID.
  final String deploymentId;

  /// The deployment's status once polling stopped.
  final enums.DeploymentStatus status;

  /// The build's logs (or a timeout explanation if polling gave up before
  /// the build finished).
  final String buildLogs;

  /// True if the build finished successfully.
  bool get succeeded => status == enums.DeploymentStatus.ready;
}
