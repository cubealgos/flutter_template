import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';

/// How many parent directories separate the Flutter SDK root from the
/// `dart` executable's own directory (`bin/cache/dart-sdk/bin/dart` — see
/// [resolveFlutterSdkRoot]'s doc comment): `bin`, `dart-sdk`, `cache`,
/// `bin`.
const int _sdkRootAncestorLevels = 4;

/// Locates the Flutter SDK root a `dart` executable was launched from,
/// without assuming FVM's `.fvm/flutter_sdk` symlink (gitignored, and
/// absent entirely in CI — see `.github/workflows/licence-check.yml`'s own
/// comment on this) or any other fixed local path.
///
/// Every `dart`/`flutter` command this workspace runs — `fvm dart ...`
/// locally, or CI's own PATH-installed Flutter — ultimately executes the
/// Dart SDK vendored *inside* the Flutter SDK, at the fixed relative
/// path `bin/cache/dart-sdk/bin/dart[.exe]` (confirmed by hand: `fvm dart`
/// resolves to `<flutter_sdk>/bin/cache/dart-sdk/bin/dart`, and CI's own
/// extracted-tarball Flutter has the same layout). Walking up four
/// directories from [dartExecutablePath] — `bin`, `dart-sdk`, `cache`,
/// `bin` — therefore finds the enclosing Flutter SDK root in either
/// environment, from [Platform.resolvedExecutable] alone, with no
/// environment-specific path guess.
String resolveFlutterSdkRoot(String dartExecutablePath) {
  final expectedSuffix = p.join('bin', 'cache', 'dart-sdk', 'bin');
  final dartSdkBinDir = p.dirname(dartExecutablePath); // .../dart-sdk/bin
  final sdkRoot = _ancestor(dartSdkBinDir, _sdkRootAncestorLevels);
  if (!p.equals(dartSdkBinDir, p.join(sdkRoot, expectedSuffix))) {
    throw CommandFailure(
      "$dartExecutablePath doesn't look like a Flutter-vendored Dart SDK "
      "(expected a '$expectedSuffix' segment) — the sbom/licence_bundle "
      "commands need to run through `fvm dart`/CI's pinned Flutter, "
      'never a bare system `dart`.',
    );
  }

  return sdkRoot;
}

/// [dir], walked up [levels] parent directories.
String _ancestor(String dir, int levels) {
  var result = dir;
  for (var i = 0; i < levels; i++) {
    result = p.dirname(result);
  }

  return result;
}

/// Reads the resolved Flutter SDK's own version out of
/// `<sdkRoot>/bin/cache/flutter.version.json` (written by the `flutter`
/// tool itself on first run — present after CI's `flutter config
/// --no-analytics` bootstrap, or any local `fvm flutter ...` invocation;
/// see `.github/workflows/licence-check.yml`). Used as the version for the
/// synthetic "Flutter SDK" SBOM component and licence-bundle note (the
/// SDK's own `dart pub deps --json` nodes for `flutter`/`sky_engine`/etc.
/// carry no real version of their own — see `dependency_graph.dart`).
String flutterSdkVersion(String sdkRoot) {
  final file = File(p.join(sdkRoot, 'bin', 'cache', 'flutter.version.json'));
  if (!file.existsSync()) {
    throw CommandFailure(
      '${file.path} not found — run `flutter config` or any `flutter` '
      'command once to populate the SDK cache before sbom/licence_bundle.',
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    throw CommandFailure('${file.path}: $e');
  }
  final version = decoded is Map ? decoded['frameworkVersion'] : null;
  if (version is! String) {
    throw CommandFailure("${file.path}: no 'frameworkVersion' string.");
  }

  return version;
}
