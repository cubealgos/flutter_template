import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/sites_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// In-memory [SitesGateway]: records every call and replays [builds] in
/// order, repeating the last one.
class FakeSitesGateway implements SitesGateway {
  /// Creates a fake whose uploads then report [builds].
  FakeSitesGateway({
    this.existsError,
    this.existing = const <String>{},
    this.builds = const <SiteBuild>[
      SiteBuild(status: 'ready', logs: '', isFinished: true),
    ],
  });

  /// Thrown by `siteExists` when set (e.g. a missing-scope 401).
  final AppwriteException? existsError;

  /// Sites that already exist.
  final Set<String> existing;

  /// The build states returned by successive `getBuild` calls.
  final List<SiteBuild> builds;

  /// Every call, as a short description.
  final List<String> calls = <String>[];

  /// Names of the files inside the last uploaded archive's source, if any
  /// were captured; here just the archive's size, to prove it was real.
  int uploadedBytes = 0;

  int _polls = 0;

  @override
  Future<bool> siteExists(String siteId) async {
    final error = existsError;
    if (error != null) throw error;

    return existing.contains(siteId);
  }

  @override
  Future<void> createSite(SiteSchema site) async =>
      calls.add('createSite(${site.id})');

  @override
  Future<String> uploadDeployment({
    required String siteId,
    required File archive,
  }) async {
    uploadedBytes = archive.lengthSync();
    calls.add('upload($siteId)');

    return 'dep-1';
  }

  @override
  Future<SiteBuild> getBuild({
    required String siteId,
    required String deploymentId,
  }) async {
    final index = _polls < builds.length ? _polls : builds.length - 1;
    _polls++;

    return builds[index];
  }
}
