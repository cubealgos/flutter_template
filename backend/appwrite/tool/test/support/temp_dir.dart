import 'dart:io';

import 'package:test/test.dart';

/// Creates a temp directory removed when the current test ends.
Directory tempDir(String prefix) {
  final dir = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() => dir.deleteSync(recursive: true));

  return dir;
}
