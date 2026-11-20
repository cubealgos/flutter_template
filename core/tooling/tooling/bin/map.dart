import 'dart:io';

import 'package:tooling/src/map_generator.dart';

/// Exit code used when no repo root (a `pubspec.yaml` with a `workspace:`
/// key) can be found above the current directory.
const int _repoRootNotFoundExitCode = 2;

/// Generates `docs/map.md` (a workspace index) and `docs/map/<member>.md`
/// (public top-level API per library file) from the workspace's `pubspec.yaml`
/// and each member's `lib/**/*.dart` sources, parsed with `package:analyzer`.
///
/// Usage:
///   dart run tooling:map            regenerate the files on disk
///   dart run tooling:map --check    fail (exit 1) if the files are stale
Future<void> main(List<String> args) async {
  final check = args.contains('--check');

  final repoRoot = findRepoRoot(Directory.current);
  if (repoRoot == null) {
    stderr.writeln(
      'map: could not find repo root (no pubspec.yaml with a '
      '"workspace:" key found above ${Directory.current.path}).',
    );
    exit(_repoRootNotFoundExitCode);
  }

  final generator = MapGenerator(repoRoot: repoRoot);
  final result = generator.generate();

  if (check) {
    final drift = generator.checkAgainstDisk(result);
    if (drift.isEmpty) {
      stdout.writeln(
        'map --check: docs/map is up to date '
        '(${result.files.length} file(s)).',
      );
      exit(0);
    }
    stderr.writeln('map --check: docs/map is out of date:');
    for (final line in drift) {
      stderr.writeln('  - $line');
    }
    stderr
      ..writeln()
      ..writeln('Run `fvm dart run melos run map` to regenerate.');
    exit(1);
  }

  generator.writeToDisk(result);
  stdout.writeln('map: wrote ${result.files.length} file(s) under docs/.');
  exit(0);
}
