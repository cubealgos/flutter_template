@Tags(['cli'])
library;

import 'package:test/test.dart';

import 'support/cli_usage_case.dart';

/// Exercises `bin/licence_bundle.dart`'s own argument parsing directly
/// (real subprocess, real usage-error exit codes) — never the happy path,
/// already covered, fully mocked, by `licence_bundle_command_test.dart`
/// against the same `LicenceBundleCommand` this CLI is a thin wrapper
/// over.
void main() {
  test('exits with usageExitCode on an unknown flag', () async {
    await expectCliUsageError(
      binPath: 'bin/licence_bundle.dart',
      args: ['--bogus'],
      stderrContains: 'unknown argument',
    );
  });

  test('exits with usageExitCode when --app has no value', () async {
    await expectCliUsageError(
      binPath: 'bin/licence_bundle.dart',
      args: ['--app'],
      stderrContains: '--app needs a value',
    );
  });
}
