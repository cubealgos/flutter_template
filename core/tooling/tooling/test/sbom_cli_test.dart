@Tags(['cli'])
library;

import 'package:test/test.dart';

import 'support/cli_usage_case.dart';

/// Exercises `bin/sbom.dart`'s own argument parsing directly (real
/// subprocess, real usage-error exit codes) — never the happy path, which
/// needs a real pub.dev call and is already covered, fully mocked, by
/// `sbom_command_test.dart` against the same `SbomCommand` this CLI is a
/// thin wrapper over.
void main() {
  test('exits with usageExitCode on an unknown flag', () async {
    await expectCliUsageError(
      binPath: 'bin/sbom.dart',
      args: ['--bogus'],
      stderrContains: 'unknown argument',
    );
  });

  test('exits with usageExitCode when --app has no value', () async {
    await expectCliUsageError(
      binPath: 'bin/sbom.dart',
      args: ['--app'],
      stderrContains: '--app needs a value',
    );
  });

  test('exits with usageExitCode on an invalid --timestamp', () async {
    await expectCliUsageError(
      binPath: 'bin/sbom.dart',
      args: ['--timestamp', 'not-a-date'],
      stderrContains: 'invalid --timestamp',
    );
  });
}
