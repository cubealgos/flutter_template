import 'dart:io';

import 'package:path/path.dart' as p;

/// Directory names never copied by [copyDirectory] — build/tooling
/// artefacts and dev-only source that a deployment bundle doesn't need.
const Set<String> excludedDirectoryNames = <String>{
  '.dart_tool',
  '.git',
  'build',
  'test',
};

/// Recursively copies [source] into [destination] (created if missing),
/// skipping any directory named in [excludedDirectoryNames] at any depth.
void copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    if (entity is Directory) {
      if (excludedDirectoryNames.contains(name)) continue;
      copyDirectory(entity, Directory(p.join(destination.path, name)));
    } else if (entity is File) {
      entity.copySync(p.join(destination.path, name));
    }
  }
}
