import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/dependency_graph.dart';
import 'package:tooling/src/flutter_sdk_locator.dart';
import 'package:tooling/src/font_licence_discovery.dart';
import 'package:tooling/src/graph_package.dart';
import 'package:tooling/src/licence_text_bundle.dart';
import 'package:tooling/src/package_config_resolver.dart';
import 'package:tooling/src/process_runner.dart';

/// Filenames recognised as a pub-cache package's own licence file,
/// matched case-insensitively — every hosted package in this workspace's
/// own closure ships a plain `LICENSE` (verified by hand across all 78),
/// but `LICENSE.md`/`LICENSE.txt`/`COPYING` are common enough
/// elsewhere on pub.dev to match generically rather than assume the bare
/// name.
final RegExp licenceFilePattern = RegExp(
  r'^(LICENSE|LICENCE|COPYING)(\..+)?$',
  caseSensitive: false,
);

/// Where `LicenceBundleCommand.run` writes its output relative to
/// `LicenceBundleCommand.repoRoot`, unless the request's `outputPath`
/// overrides it.
String defaultLicenceBundleOutputPath(String appPackageName) =>
    p.join('build', 'release', appPackageName, 'THIRD_PARTY_LICENSES');

/// Options for one [LicenceBundleCommand.run] call — see
/// `sbom_command.dart`'s `SbomRequest` for why this is a record rather
/// than loose parameters.
typedef LicenceBundleRequest = ({String appPackageName, String? outputPath});

/// The default request: `apps/app`, default output path.
const LicenceBundleRequest defaultLicenceBundleRequest = (
  appPackageName: 'app',
  outputPath: null,
);

/// `licence_bundle`: writes a single `THIRD_PARTY_LICENSES` text file for
/// one app's resolved runtime dependency closure — the redistribution
/// obligation MIT/BSD/etc. licences carry on their own terms, separate
/// from (and, per the dependency-licence policy's "Distinct obligations"
/// section, not to be conflated with) any upstream `NOTICE` requirement.
///
/// Third-party only: a first-party workspace member's own code is never
/// included (it isn't a third-party obligation), but its directory *is*
/// still scanned for bundled font licences (`ui`, in particular, is where
/// font assets live) — see [discoverFontLicenceFiles]. Also includes
/// one shared "Flutter SDK" note whenever the closure includes any
/// SDK-sourced component (`flutter`, `sky_engine`, …).
///
/// Fails loudly — [CommandFailure], never a silently skipped package —
/// the moment any hosted package's or the Flutter SDK's licence text
/// can't be found on disk.
class LicenceBundleCommand {
  /// Creates the command. [dartExecutable] defaults to
  /// [Platform.resolvedExecutable] — see `sbom_command.dart`'s identical
  /// parameter for why.
  LicenceBundleCommand({
    required this.repoRoot,
    required this.runner,
    String? dartExecutable,
    this.out = _defaultOut,
    this.err = _defaultErr,
  }) : dartExecutable = dartExecutable ?? Platform.resolvedExecutable;

  /// The workspace root every relative path is resolved against.
  final String repoRoot;

  /// Runs `dart pub deps --json` (real process in production, scripted in
  /// tests).
  final ProcessRunner runner;

  /// The `dart` executable [resolveFlutterSdkRoot] locates the Flutter
  /// SDK from.
  final String dartExecutable;

  /// Sink for progress messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  /// Runs the command for [request], writing the bundle to disk and
  /// returning the process exit code.
  Future<int> run([
    LicenceBundleRequest request = defaultLicenceBundleRequest,
  ]) => runCatchingFailures(() => _run(request), err);

  Future<void> _run(LicenceBundleRequest request) async {
    final graph = await resolveDependencyGraph(
      runner: runner,
      repoRoot: repoRoot,
      dartExecutable: dartExecutable,
    );
    if (!graph.containsKey(request.appPackageName)) {
      throw CommandFailure(
        "licence_bundle: no package named '${request.appPackageName}' in "
        'the resolved workspace graph.',
      );
    }
    final closure = transitiveClosure(graph, request.appPackageName);
    final resolver = PackageConfigResolver.load(repoRoot);

    final entries = [
      ..._hostedEntries(closure, resolver),
      ..._flutterSdkEntry(closure),
      ..._fontEntries(request.appPackageName, closure, resolver),
    ];

    final text = buildLicenceBundleText(entries);
    final outputPath = p.join(
      repoRoot,
      request.outputPath ??
          defaultLicenceBundleOutputPath(request.appPackageName),
    );
    File(outputPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);

    out(
      'licence_bundle: wrote ${entries.length} licence(s) '
      "(${text.length} bytes) for '${request.appPackageName}' to "
      '$outputPath.',
    );
  }

  List<LicenceBundleEntry> _hostedEntries(
    List<GraphPackage> closure,
    PackageConfigResolver resolver,
  ) => [
    for (final pkg in closure)
      if (pkg.source == hostedSource)
        (
          heading: '${pkg.name} ${pkg.version}',
          licenceText: _readLicenceText(pkg.name, pkg.version, resolver),
        ),
  ];

  String _readLicenceText(
    String name,
    String version,
    PackageConfigResolver resolver,
  ) {
    final dir = resolver.directoryFor(name);
    if (dir == null || !dir.existsSync()) {
      throw CommandFailure(
        'licence_bundle: no on-disk directory resolved for $name '
        '$version (run `fvm dart pub get` first).',
      );
    }
    final file = _findLicenceFile(dir);
    if (file == null) {
      throw CommandFailure(
        'licence_bundle: no LICENSE text found for $name $version in '
        '${dir.path} — third-party licence bundling requires one '
        '(dependency-license-policy.md, "Distinct obligations").',
      );
    }

    return file.readAsStringSync();
  }

  File? _findLicenceFile(Directory dir) {
    final matches =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => licenceFilePattern.hasMatch(p.basename(f.path)))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    if (matches.isEmpty) return null;

    return matches.firstWhere(
      (f) => p.basename(f.path).toUpperCase() == 'LICENSE',
      orElse: () => matches.first,
    );
  }

  List<LicenceBundleEntry> _flutterSdkEntry(List<GraphPackage> closure) {
    if (!closure.any((pkg) => pkg.source == sdkSource)) return const [];

    final sdkRoot = resolveFlutterSdkRoot(dartExecutable);
    final version = flutterSdkVersion(sdkRoot);
    final licenceFile = File(p.join(sdkRoot, 'LICENSE'));
    if (!licenceFile.existsSync()) {
      throw CommandFailure(
        'licence_bundle: no LICENSE found at ${licenceFile.path} for the '
        'Flutter SDK.',
      );
    }

    return [
      (
        heading: 'Flutter SDK $version',
        licenceText: licenceFile.readAsStringSync(),
      ),
    ];
  }

  List<LicenceBundleEntry> _fontEntries(
    String appPackageName,
    List<GraphPackage> closure,
    PackageConfigResolver resolver,
  ) {
    final ownedDirs = <FontOwnedDir>[
      if (resolver.directoryFor(appPackageName) case final dir?)
        (packageName: appPackageName, dir: dir),
      for (final pkg in closure)
        if (pkg.source == rootSource)
          if (resolver.directoryFor(pkg.name) case final dir?)
            (packageName: pkg.name, dir: dir),
    ];
    final found = discoverFontLicenceFiles(
      repoRoot: repoRoot,
      ownedDirs: ownedDirs,
    );

    return [
      for (final font in found)
        (
          heading:
              'Font licence — ${font.ownerPackage} '
              '(${p.basename(font.file.path)})',
          licenceText: font.file.readAsStringSync(),
        ),
    ];
  }

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);
}
