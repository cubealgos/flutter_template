import 'dart:io';

import 'package:path/path.dart' as p;

/// Recursively copies [source] into [destination], which must not yet exist.
///
/// Shared by every test that copies a fixture workspace into a fresh temp
/// directory before mutating it (`map_generator_test.dart`,
/// `duplicate_index_cleanup_test.dart`) — extracted here rather than
/// duplicated per file, which `avoid_duplicate_code` flagged when it was.
void copyDirRecursively(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final entity in source.listSync()) {
    final name = p.basename(entity.path);
    if (entity is Directory) {
      copyDirRecursively(entity, Directory(p.join(destination.path, name)));
    } else if (entity is File) {
      entity.copySync(p.join(destination.path, name));
    }
  }
}
