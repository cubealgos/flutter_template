import 'dart:io';

import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';

/// Runs `dart run <binPath> <args>` (from the current working directory —
/// a package root, for every caller) and asserts it exits with
/// [usageExitCode] and stderr containing [stderrContains].
///
/// Factored out of `sbom_cli_test.dart` and `licence_bundle_cli_test.dart`,
/// each of which had a near-identical usage-error case for their own bin
/// (solid_lints' `avoid_duplicate_code` correctly flagged the cross-file
/// structural overlap — real behavior differs only in which bin, which
/// args and which message, so those three are exactly this function's
/// parameters).
Future<void> expectCliUsageError({
  required String binPath,
  required List<String> args,
  required String stderrContains,
}) async {
  final result = await Process.run('dart', [
    'run',
    binPath,
    ...args,
  ], workingDirectory: Directory.current.path);

  expect(result.exitCode, usageExitCode);
  expect(result.stderr, contains(stderrContains));
}
