import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/archiver.dart';
import 'package:appwrite_tool/src/deploy/sites_gateway.dart';
import 'package:path/path.dart' as p;

/// Archives a Site's finished static build, uploads it as a deployment and
/// waits for the build to be ready.
class SiteDeployer {
  /// Creates a deployer over [gateway]. [wait] and [timeout] exist so tests
  /// need not really sleep.
  SiteDeployer(
    this.gateway, {
    Future<void> Function(Duration)? wait,
    this.pollInterval = const Duration(seconds: 3),
    this.timeout = const Duration(minutes: 5),
  }) : _wait = wait ?? Future<void>.delayed;

  /// The Sites operations.
  final SitesGateway gateway;

  /// How long to wait between build-status polls.
  final Duration pollInterval;

  /// How long to poll before giving up.
  final Duration timeout;

  final Future<void> Function(Duration) _wait;

  /// Resolves [site]'s build directory under [repoRoot]; throws
  /// [SiteBuildMissingException] when it is missing or empty.
  Directory buildDirectory(SiteSchema site, Directory repoRoot) {
    final dir = Directory(p.join(repoRoot.path, site.buildOutputPath));
    if (!dir.existsSync() || dir.listSync().isEmpty) {
      throw SiteBuildMissingException(site, dir.path);
    }

    return dir;
  }

  /// Reports what [deploy] would do, changing nothing.
  Future<SiteDeployment> dryRun(SiteSchema site, Directory repoRoot) async {
    final dir = buildDirectory(site, repoRoot);
    final exists = await gateway.siteExists(site.id);

    return SiteDeployment(
      siteId: site.id,
      succeeded: true,
      summary:
          '${exists ? 'would deploy to' : 'would create and deploy to'} site '
          '"${site.id}" from ${site.buildOutputPath} '
          '(${dir.listSync().length} top-level entries)',
    );
  }

  /// Creates [site] if absent, uploads its build and waits for it.
  /// [scratch] holds the temporary archive.
  Future<SiteDeployment> deploy(
    SiteSchema site,
    Directory repoRoot, {
    required Directory scratch,
  }) async {
    final dir = buildDirectory(site, repoRoot);
    if (!await gateway.siteExists(site.id)) await gateway.createSite(site);

    final archive = File(p.join(scratch.path, '${site.id}-site.tar.gz'));
    await createDeploymentArchive(sourceDir: dir, outputFile: archive);
    final String deploymentId;
    try {
      deploymentId = await gateway.uploadDeployment(
        siteId: site.id,
        archive: archive,
      );
    } finally {
      if (archive.existsSync()) archive.deleteSync();
    }

    final deadline = DateTime.now().add(timeout);
    while (true) {
      final build = await gateway.getBuild(
        siteId: site.id,
        deploymentId: deploymentId,
      );
      if (build.isFinished) {
        return SiteDeployment(
          siteId: site.id,
          deploymentId: deploymentId,
          succeeded: build.succeeded,
          summary: build.succeeded
              ? 'deployed and activated $deploymentId'
              : 'build ${build.status} for $deploymentId\n${build.logs}',
        );
      }
      if (DateTime.now().isAfter(deadline)) {
        return SiteDeployment(
          siteId: site.id,
          deploymentId: deploymentId,
          succeeded: false,
          summary:
              'timed out after ${timeout.inMinutes} min, still '
              '"${build.status}"',
        );
      }
      await _wait(pollInterval);
    }
  }
}

/// Thrown when a Site's build output directory is missing or empty: the
/// tool never builds, the caller does (see [SiteSchema.buildCommand]).
class SiteBuildMissingException implements Exception {
  /// Creates the exception.
  const SiteBuildMissingException(this.site, this.directory);

  /// The Site that could not be deployed.
  final SiteSchema site;

  /// The directory that was expected to hold the build.
  final String directory;

  @override
  String toString() =>
      'No build output for site "${site.id}" at $directory. Build it first '
      '(from the repo root): ${site.buildCommand}';
}

/// What deploying one Site did (or, for a dry run, would do).
class SiteDeployment {
  /// Creates a result.
  const SiteDeployment({
    required this.siteId,
    required this.succeeded,
    required this.summary,
    this.deploymentId,
  });

  /// The Site.
  final String siteId;

  /// Whether the deployment is ready (always true for a dry run that found
  /// nothing wrong).
  final bool succeeded;

  /// A one-line, human-readable outcome (the build log on failure).
  final String summary;

  /// The created deployment, null for a dry run.
  final String? deploymentId;
}
