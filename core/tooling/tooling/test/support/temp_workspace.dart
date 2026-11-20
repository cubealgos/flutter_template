import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A disposable temp directory for a single test — shared by every
/// licence-check test that needs to write a fixture file (a `pubspec.lock`
/// or a `tool/licence-exceptions.yaml`) without touching the real repo.
class TempWorkspace {
  const TempWorkspace._(this.root);

  /// Creates a fresh temp directory named with [prefix].
  factory TempWorkspace.create(String prefix) =>
      TempWorkspace._(Directory.systemTemp.createTempSync(prefix));

  /// The workspace's root directory — delete this to clean up everything.
  final Directory root;

  /// Writes [contents] to `<root>/<relativePath>`, creating parent
  /// directories as needed, and returns the file's full path.
  String writeFile(String relativePath, String contents) {
    final file = File(p.join(root.path, relativePath))
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);

    return file.path;
  }

  /// The [File] at `<root>/<relativePath>` — doesn't require it to exist;
  /// callers created by [writeFile] read it back via this, and a
  /// still-missing path is itself sometimes the assertion under test.
  File file(String relativePath) => File(p.join(root.path, relativePath));

  /// Writes `<root>/.dart_tool/package_config.json` with the given
  /// [packages] (each a raw `{"name": ..., "rootUri": ...}` map, as
  /// `PackageConfigResolver`/`PubMarkCommand` read it) — shared by every
  /// test that fakes a resolved pub graph rather than running a real
  /// `pub get` (`package_config_resolver_test.dart`,
  /// `pub_mark_command_test.dart`).
  String writePackageConfig(List<Map<String, String>> packages) => writeFile(
    p.join('.dart_tool', 'package_config.json'),
    jsonEncode({'configVersion': 2, 'packages': packages}),
  );

  /// Deletes [root] and everything under it.
  void dispose() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}
