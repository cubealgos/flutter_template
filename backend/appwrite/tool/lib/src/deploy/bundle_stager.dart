import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/directory_copy.dart';
import 'package:appwrite_tool/src/deploy/path_dependencies.dart';
import 'package:appwrite_tool/src/deploy/pubspec_lock.dart';
import 'package:appwrite_tool/src/deploy/pubspec_rewriter.dart';
import 'package:path/path.dart' as p;

/// The name of the directory, inside a staged bundle, that every path
/// dependency is vendored into.
const String vendorDirectoryName = 'vendor';

/// One path dependency still to be vendored: its declared package [name]
/// and where its real source lives on disk.
class _PendingVendorEntry {
  const _PendingVendorEntry(this.name, this.sourceDir);

  final String name;
  final Directory sourceDir;
}

/// Stages a [FunctionSchema] into a standalone, deployable directory: a copy
/// of the function's own source, every path dependency it transitively
/// needs vendored under `vendor/<name>`, and every pubspec.yaml (the
/// function's own, and each vendored package's) rewritten by
/// [PubspecRewriter] to resolve without the workspace.
class BundleStager {
  /// Creates a stager for the workspace rooted at [repoRoot], pinning
  /// hosted dependencies from [lockfile].
  const BundleStager({
    required this.repoRoot,
    required this.lockfile,
    this.rewriter = const PubspecRewriter(),
  });

  /// The workspace root — [FunctionSchema.path] is relative to this.
  final Directory repoRoot;

  /// The workspace's resolved hosted dependency versions.
  final PubspecLock lockfile;

  /// The rewriter used on every staged pubspec.yaml.
  final PubspecRewriter rewriter;

  /// Stages [function] into a fresh temp directory and returns it.
  Directory stage(FunctionSchema function) {
    final stagingDir = Directory.systemTemp.createTempSync(
      'deploy_${function.id}_',
    );
    final functionSourceDir = Directory(p.join(repoRoot.path, function.path));
    copyDirectory(functionSourceDir, stagingDir);

    final vendored = _vendorPathDependencies(
      stagingPubspec: File(p.join(stagingDir.path, 'pubspec.yaml')),
      originalBaseDir: functionSourceDir,
      stagingDir: stagingDir,
    );

    _rewriteStagedPubspec(
      File(p.join(stagingDir.path, 'pubspec.yaml')),
      vendorPrefix: vendorDirectoryName,
    );
    for (final name in vendored) {
      _rewriteStagedPubspec(
        File(
          p.join(stagingDir.path, vendorDirectoryName, name, 'pubspec.yaml'),
        ),
        // Every vendored package lands as a sibling directly under
        // vendor/, so a vendored package's own path dependencies (were it
        // to have any) point at "../<name>", not "vendor/<name>" again.
        vendorPrefix: '..',
      );
    }

    return stagingDir;
  }

  /// Copies every path dependency the staged function (transitively) needs
  /// into `vendor/<name>`, flattened one level deep, and returns the set of
  /// vendored package names.
  ///
  /// [stagingPubspec] is the just-copied, not-yet-rewritten pubspec.yaml
  /// (its `path:` values are still relative to [originalBaseDir], the real
  /// on-disk location the copy came from — not to [stagingDir]).
  Set<String> _vendorPathDependencies({
    required File stagingPubspec,
    required Directory originalBaseDir,
    required Directory stagingDir,
  }) {
    final vendored = <String>{};
    final worklist = <_PendingVendorEntry>[
      ..._pathDepsFrom(stagingPubspec, baseDir: originalBaseDir),
    ];

    while (worklist.isNotEmpty) {
      final next = worklist.removeLast();
      if (!vendored.add(next.name)) continue;

      final vendorDir = Directory(
        p.join(stagingDir.path, vendorDirectoryName, next.name),
      );
      copyDirectory(next.sourceDir, vendorDir);

      worklist.addAll(
        _pathDepsFrom(
          File(p.join(vendorDir.path, 'pubspec.yaml')),
          baseDir: next.sourceDir,
        ),
      );
    }

    return vendored;
  }

  List<_PendingVendorEntry> _pathDepsFrom(
    File pubspecFile, {
    required Directory baseDir,
  }) {
    final paths = pathDependenciesOf(pubspecFile.readAsStringSync());

    return paths.entries
        .map(
          (entry) => _PendingVendorEntry(
            entry.key,
            Directory(p.normalize(p.join(baseDir.path, entry.value))),
          ),
        )
        .toList();
  }

  void _rewriteStagedPubspec(File pubspecFile, {required String vendorPrefix}) {
    final rewritten = rewriter.rewrite(
      originalYaml: pubspecFile.readAsStringSync(),
      lockedVersions: lockfile.hostedVersions,
      vendorPrefix: vendorPrefix,
    );
    pubspecFile.writeAsStringSync(rewritten);
  }
}
