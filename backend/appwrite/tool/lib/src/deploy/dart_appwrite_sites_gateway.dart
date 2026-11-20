import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/deployer.dart';
import 'package:appwrite_tool/src/deploy/sites_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart' as enums;

const int _notFound = 404;

/// [SitesGateway] backed by `package:dart_appwrite`'s `Sites` service
/// (29.0.0 — read from its source: `create`, `get`, `createDeployment`,
/// `getDeployment`).
class DartAppwriteSitesGateway implements SitesGateway {
  /// Creates a gateway over [client].
  DartAppwriteSitesGateway(Client client) : _sites = Sites(client);

  final Sites _sites;

  @override
  Future<bool> siteExists(String siteId) async {
    try {
      await _sites.get(siteId: siteId);

      return true;
    } on AppwriteException catch (e) {
      if (e.code == _notFound) return false;
      rethrow;
    }
  }

  @override
  Future<void> createSite(SiteSchema site) async {
    // Static hosting of a prebuilt directory: framework `other`, the
    // `static` adapter, empty install/build commands. `node-22` is the
    // build runtime Appwrite requires even when nothing builds.
    await _sites.create(
      siteId: site.id,
      name: site.name,
      framework: enums.Framework.other,
      buildRuntime: enums.BuildRuntime.node22,
      adapter: enums.Adapter.xstatic,
      installCommand: '',
      buildCommand: '',
      outputDirectory: './',
      fallbackFile: site.fallbackFile.isEmpty ? null : site.fallbackFile,
    );
  }

  @override
  Future<String> uploadDeployment({
    required String siteId,
    required File archive,
  }) async {
    final deployment = await _sites.createDeployment(
      siteId: siteId,
      code: InputFile.fromPath(path: archive.path),
      activate: true,
    );

    return deployment.$id;
  }

  @override
  Future<SiteBuild> getBuild({
    required String siteId,
    required String deploymentId,
  }) async {
    final deployment = await _sites.getDeployment(
      siteId: siteId,
      deploymentId: deploymentId,
    );

    return SiteBuild(
      status: deployment.status.value,
      logs: deployment.buildLogs,
      isFinished: finishedDeploymentStatuses.contains(deployment.status),
    );
  }
}
