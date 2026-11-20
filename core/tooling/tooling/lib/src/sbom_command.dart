import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/cyclonedx_document.dart';
import 'package:tooling/src/dependency_graph.dart';
import 'package:tooling/src/flutter_sdk_locator.dart';
import 'package:tooling/src/graph_package.dart';
import 'package:tooling/src/locked_package.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';
import 'package:tooling/src/root_licence.dart';
import 'package:tooling/src/sbom_component.dart';
import 'package:tooling/src/uuid_v4.dart';
import 'package:tooling/src/verified_licence.dart';
import 'package:tooling/src/workspace_purl_namespace.dart';

/// The licence used for every Flutter-SDK-sourced component (`flutter`,
/// `sky_engine`, `flutter_web_plugins`, `flutter_localizations`, …) —
/// read once by hand from `<flutter_sdk>/LICENSE` (BSD-3-Clause, "The
/// Flutter Authors"; verified 2026-09-25) since none of those packages
/// are published to pub.dev for [PubDevLicenceClient] to query.
const String flutterSdkLicence = 'BSD-3-Clause';

/// Where [SbomCommand.run] writes its output relative to `repoRoot`,
/// unless the request's `outputPath` overrides it: `sbom.cdx.json` inside
/// `build/release/`, in a subdirectory named after [appPackageName] —
/// under `build/`, already gitignored workspace-wide.
String defaultSbomOutputPath(String appPackageName) =>
    p.join('build', 'release', appPackageName, 'sbom.cdx.json');

/// Options for one [SbomCommand.run] call, grouped into a record (rather
/// than four-plus loose parameters — see root `analysis_options.yaml`'s
/// `number_of_parameters` threshold) so every field can stay named and
/// self-describing at the call site.
typedef SbomRequest = ({
  String appPackageName,
  DateTime? timestamp,
  String? serialNumber,
  String? outputPath,
});

/// The default request: `apps/app` (the one release artifact this
/// template's own CI verifies — see `.github/workflows/release-artifacts.yml`),
/// a real timestamp/serial number, and the default output path.
const SbomRequest defaultSbomRequest = (
  appPackageName: 'app',
  timestamp: null,
  serialNumber: null,
  outputPath: null,
);

/// `sbom`: generates a CycloneDX 1.6 JSON SBOM for one app's resolved
/// runtime dependency closure (default `apps/app`; see
/// `dependency_graph.dart`'s [transitiveClosure]) — the CRA's "generate a
/// CycloneDX SBOM per release from the first release" lever (the EU Cyber
/// Resilience Act's practical tool for vulnerability reporting).
///
/// Reuses exactly the pieces `licence_check_command.dart` already has for
/// walking `pubspec.lock` and resolving a package's pub.dev-reported
/// licence(s) ([PubDevLicenceClient], `tool/licence-exceptions.yaml`'s
/// `verified:` overrides) — deliberately *not* that command's own
/// allow/deny verdict machinery, since documenting "what licence did we
/// find" and enforcing "is that licence allowed" are different jobs (the
/// latter stays `licence_check`'s alone).
class SbomCommand {
  /// Creates the command. [dartExecutable] defaults to
  /// [Platform.resolvedExecutable] — the same Dart binary this process is
  /// itself running under, which [resolveFlutterSdkRoot] needs to be
  /// Flutter-vendored (i.e. launched via `fvm dart`/CI's pinned Flutter,
  /// never a bare system `dart`).
  SbomCommand({
    required this.repoRoot,
    required this.runner,
    required this.licenceClient,
    String? dartExecutable,
    this.out = _defaultOut,
    this.err = _defaultErr,
  }) : dartExecutable = dartExecutable ?? Platform.resolvedExecutable;

  /// The workspace root every relative path is resolved against.
  final String repoRoot;

  /// Runs `dart pub deps --json` (real process in production, scripted in
  /// tests).
  final ProcessRunner runner;

  /// Resolves each hosted package's pub.dev-reported licence tags.
  final PubDevLicenceClient licenceClient;

  /// The `dart` executable [resolveFlutterSdkRoot] locates the Flutter
  /// SDK from.
  final String dartExecutable;

  /// Sink for progress messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  /// Runs the command for [request], writing the CycloneDX document to
  /// disk and returning the process exit code.
  Future<int> run([SbomRequest request = defaultSbomRequest]) =>
      runCatchingFailures(() => _run(request), err);

  Future<void> _run(SbomRequest request) async {
    final graph = await resolveDependencyGraph(
      runner: runner,
      repoRoot: repoRoot,
      dartExecutable: dartExecutable,
    );
    final app = graph[request.appPackageName];
    if (app == null) {
      throw CommandFailure(
        "sbom: no package named '${request.appPackageName}' in the "
        'resolved workspace graph.',
      );
    }
    final closure = transitiveClosure(graph, request.appPackageName);
    final namespace = workspacePurlNamespace(repoRoot);
    final components = await _buildComponents(closure, namespace);

    final document = buildCycloneDxBom((
      appName: request.appPackageName,
      appVersion: app.version,
      components: components,
      timestamp: (request.timestamp ?? DateTime.now()).toUtc(),
      serialNumber: request.serialNumber ?? generateUuidV4(),
      toolVersion: graph['tooling']?.version ?? '0.0.0',
      namespace: namespace,
    ));

    final outputPath = p.join(
      repoRoot,
      request.outputPath ?? defaultSbomOutputPath(request.appPackageName),
    );
    File(outputPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(document)}\n',
      );

    out(
      'sbom: wrote ${components.length} component(s) for '
      "'${request.appPackageName}' to $outputPath.",
    );
  }

  Future<List<SbomComponent>> _buildComponents(
    List<GraphPackage> closure,
    String namespace,
  ) async {
    final sha256ByKey = _lockfileSha256ByKey();
    final verified = loadVerifiedLicences(
      p.join(repoRoot, 'tool', 'licence-exceptions.yaml'),
    );
    final firstPartyLicenceId = _resolveFirstPartyLicenceId();
    // Resolved lazily — most apps (e.g. apps/website) have no SDK
    // component in their closure at all, and resolving it eagerly would
    // needlessly require a populated Flutter SDK cache for those.
    String? flutterVersion;
    String currentFlutterVersion() => flutterVersion ??= flutterSdkVersion(
      resolveFlutterSdkRoot(dartExecutable),
    );

    final components = <SbomComponent>[];
    for (final pkg in closure) {
      components.add(switch (pkg.source) {
        hostedSource => await _hostedComponent(pkg, sha256ByKey, verified),
        rootSource => _firstPartyComponent(pkg, namespace, firstPartyLicenceId),
        _ => _sdkComponent(pkg, currentFlutterVersion()),
      });
    }

    return components;
  }

  /// The SPDX id every first-party workspace component gets, read once
  /// from the root `LICENSE` file (see `root_licence.dart`) — `null`
  /// (plus a printed warning, not a thrown [CommandFailure]: an
  /// unidentifiable root licence shouldn't block the whole SBOM) if it
  /// can't be identified.
  String? _resolveFirstPartyLicenceId() {
    final id = readRootLicenceSpdxId(repoRoot);
    if (id == null) {
      err(
        'sbom: could not identify an SPDX id from the root LICENSE file — '
        'first-party components will carry no licence.',
      );
    }

    return id;
  }

  Future<SbomComponent> _hostedComponent(
    GraphPackage pkg,
    Map<String, String> sha256ByKey,
    List<VerifiedLicence> verified,
  ) async {
    final licences = await licenceClient.licencesFor(pkg.name, pkg.version);

    return SbomComponent(
      type: 'library',
      name: pkg.name,
      version: pkg.version,
      purl: 'pkg:pub/${pkg.name}@${pkg.version}',
      licences: _resolveLicences(pkg, licences, verified),
      sha256: sha256ByKey['${pkg.name}@${pkg.version}'],
    );
  }

  List<SbomLicence> _resolveLicences(
    GraphPackage pkg,
    PackageLicences licences,
    List<VerifiedLicence> verified,
  ) {
    final candidates = licences.spdxCandidates;
    if (candidates.isNotEmpty) {
      return [for (final id in candidates) SbomLicence.spdx(id)];
    }
    for (final entry in verified) {
      if (entry.covers(pkg.name, pkg.version)) {
        return [SbomLicence.spdx(entry.licence)];
      }
    }

    return [
      for (final tag in licences.unrecognisedTags) SbomLicence.freeText(tag),
    ];
  }

  SbomComponent _firstPartyComponent(
    GraphPackage pkg,
    String namespace,
    String? licenceId,
  ) => SbomComponent(
    type: 'library',
    name: pkg.name,
    version: pkg.version,
    purl: 'pkg:generic/$namespace/${pkg.name}@${pkg.version}',
    licences: licenceId == null ? const [] : [SbomLicence.spdx(licenceId)],
  );

  SbomComponent _sdkComponent(GraphPackage pkg, String flutterVersion) =>
      SbomComponent(
        type: 'framework',
        name: pkg.name,
        version: flutterVersion,
        purl: 'pkg:generic/flutter-sdk/${pkg.name}@$flutterVersion',
        licences: const [SbomLicence.spdx(flutterSdkLicence)],
      );

  Map<String, String> _lockfileSha256ByKey() {
    final lockfilePath = p.join(repoRoot, 'pubspec.lock');
    if (!File(lockfilePath).existsSync()) return const {};

    return {
      for (final locked in hostedPackagesFromLockfile(lockfilePath))
        '${locked.name}@${locked.version}': ?locked.sha256,
    };
  }

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);
}
