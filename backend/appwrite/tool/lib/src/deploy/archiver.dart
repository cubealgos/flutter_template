import 'dart:io';

import 'package:archive/archive_io.dart';

/// Creates a gzip-compressed tar archive of everything under [sourceDir],
/// written to [outputFile], and returns [outputFile].
///
/// Archive entries are relative to [sourceDir] itself (`pubspec.yaml`,
/// `lib/main.dart`, …) — **not** nested under a directory named after
/// [sourceDir]'s own basename. That distinction matters here:
/// `package:archive`'s own `TarFileEncoder.tarDirectory` convenience method
/// always nests entries under the source directory's basename (there is no
/// way to pass `includeDirName: false` through it), which would upload a
/// deployment where the server can't find `pubspec.yaml` at the archive
/// root — Appwrite's build step (`dart pub get`, then AOT-compiling the
/// function's entrypoint) expects it there. This uses the lower-level
/// `create`/`addDirectory`/`close` calls directly, with
/// `includeDirName: false`, to get that right.
Future<File> createDeploymentArchive({
  required Directory sourceDir,
  required File outputFile,
}) async {
  final tarPath = '${outputFile.path}.tmp-tar';
  final encoder = TarFileEncoder()..create(tarPath);
  await encoder.addDirectory(sourceDir, includeDirName: false);
  await encoder.close();

  final input = InputFileStream(tarPath);
  final output = OutputFileStream(outputFile.path);
  const GZipEncoder().encodeStream(input, output);
  await input.close();
  await output.close();
  await File(tarPath).delete();

  return outputFile;
}
