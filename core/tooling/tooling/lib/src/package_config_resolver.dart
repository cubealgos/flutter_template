import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';

/// Resolves a resolved package's on-disk root directory from
/// `.dart_tool/package_config.json` (written by `pub get`; gitignored,
/// never committed) — the same file `dart`/`flutter` themselves consult
/// to turn a `package:name/...` import into a path, so this reads a
/// package's location the way the tool actually resolves it rather than
/// guessing a `~/.pub-cache/hosted/pub.dev/<name>-<version>` path by hand
/// (which would silently break for a package hosted anywhere else, e.g. a
/// git dependency, and can't resolve a workspace member's own directory
/// at all).
///
/// See the package_config format (`configVersion: 2`) `dart-lang/language`
/// documents: each entry's `rootUri` is either an absolute `file://` URI
/// (a pub-cache-hosted package) or a path *relative to the
/// `package_config.json` file's own directory* (`.dart_tool/`, not the
/// repo root — a workspace member's `rootUri` is typically `../apps/app`,
/// one level up from `.dart_tool/` then down into the member).
class PackageConfigResolver {
  PackageConfigResolver._(this._dirsByName);

  /// Loads `<repoRoot>/.dart_tool/package_config.json`. Throws
  /// [CommandFailure] if it doesn't exist (run `fvm dart pub get` first)
  /// or isn't valid.
  factory PackageConfigResolver.load(String repoRoot) {
    final file = File(p.join(repoRoot, '.dart_tool', 'package_config.json'));
    if (!file.existsSync()) {
      throw CommandFailure(
        '${file.path} not found — run `fvm dart pub get` first.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw CommandFailure('${file.path}: $e');
    }
    if (decoded is! Map || decoded['packages'] is! List) {
      throw CommandFailure("${file.path}: no 'packages' list.");
    }

    final dartToolDir = file.parent.path;
    final dirsByName = <String, Directory>{
      for (final entry in _entries(decoded['packages'] as List, dartToolDir))
        entry.key: entry.value,
    };

    return PackageConfigResolver._(dirsByName);
  }

  final Map<String, Directory> _dirsByName;

  /// Every resolved package's on-disk root directory, by name — the same
  /// data [directoryFor] looks up one at a time, exposed as a whole for a
  /// caller that needs to walk the entire graph (e.g. `PubMarkCommand`,
  /// which touches a cache-freshness marker for every *hosted* entry).
  Map<String, Directory> get allDirectories => Map.unmodifiable(_dirsByName);

  /// The on-disk root directory for package [name], or `null` if [name]
  /// isn't in the resolved package graph.
  Directory? directoryFor(String name) => _dirsByName[name];

  static Iterable<MapEntry<String, Directory>> _entries(
    List<Object?> packages,
    String dartToolDir,
  ) sync* {
    for (final raw in packages) {
      if (raw is! Map) continue;
      final name = raw['name'];
      final rootUri = raw['rootUri'];
      if (name is! String || rootUri is! String) continue;
      yield MapEntry(name, _resolveDir(rootUri, dartToolDir));
    }
  }

  static Directory _resolveDir(String rootUri, String dartToolDir) {
    final uri = Uri.parse(rootUri);
    final path = uri.isAbsolute
        ? uri.toFilePath()
        : p.join(dartToolDir, rootUri);

    // `Directory.fromUri`/`Uri.toFilePath` on a directory URI keeps its
    // trailing separator; normalizing strips it, so both the absolute
    // and relative branches yield the exact same shape of path.
    return Directory(p.normalize(path));
  }
}
