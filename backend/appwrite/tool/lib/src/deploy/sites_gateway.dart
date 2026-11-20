import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';

/// The Appwrite `Sites` operations `SiteDeployer` needs, behind an
/// interface so deployment logic is unit-tested with a fake — no live
/// Appwrite project required. `DartAppwriteSitesGateway` is the real one.
abstract class SitesGateway {
  /// Whether the Site [siteId] exists.
  Future<bool> siteExists(String siteId);

  /// Creates [site] as a static Site (no install/build step: the uploaded
  /// archive already is the build).
  Future<void> createSite(SiteSchema site);

  /// Uploads [archive] (a tar.gz of the finished build) as a new
  /// deployment of [siteId], activating it when it is ready; returns the
  /// deployment ID.
  Future<String> uploadDeployment({
    required String siteId,
    required File archive,
  });

  /// The current build state of [deploymentId].
  Future<SiteBuild> getBuild({
    required String siteId,
    required String deploymentId,
  });
}

/// A Site deployment's build state.
class SiteBuild {
  /// Creates a state.
  const SiteBuild({
    required this.status,
    required this.logs,
    required this.isFinished,
  });

  /// Appwrite's status value (`processing`, `building`, `ready`, `failed`,
  /// `canceled`, ...).
  final String status;

  /// The build log.
  final String logs;

  /// Whether the build stopped running (successfully or not).
  final bool isFinished;

  /// Whether the build finished successfully.
  bool get succeeded => isFinished && status == 'ready';
}
