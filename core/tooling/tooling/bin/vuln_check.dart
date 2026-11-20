import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/osv_client.dart';
import 'package:tooling/src/vuln_check_command.dart';

/// `vuln_check`: queries the public OSV database (no account) for every
/// `source: hosted` package version in the workspace's `pubspec.lock` plus
/// `core/architecture/mvc_lints/pubspec.lock`, and exits non-zero on any
/// critical or high advisory not covered by an unexpired entry in
/// `tool/vuln-exceptions.yaml` (or on an expired entry).
///
/// Usage: `fvm dart run tooling:vuln_check` (repo root or a worktree).
/// `--lockfile <path>` (repeatable; relative to the current directory or
/// absolute) replaces the default lockfiles; `--exceptions <path>` replaces the
/// exceptions file.
Future<void> main(List<String> args) async {
  final lockfiles = <String>[];
  String? exceptions;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--lockfile' when i + 1 < args.length:
        lockfiles.add(args[++i]);
      case '--exceptions' when i + 1 < args.length:
        exceptions = args[++i];
      default:
        stderr.writeln('vuln_check: unknown argument ${args[i]}');
        exit(usageExitCode);
    }
  }
  final client = OsvClient();
  var code = 0;
  try {
    final command = VulnCheckCommand(
      repoRoot: Directory.current.path,
      client: client,
      exceptionsPath: exceptions ?? 'tool/vuln-exceptions.yaml',
      lockfilePaths: lockfiles.isEmpty
          ? const ['pubspec.lock', 'core/architecture/mvc_lints/pubspec.lock']
          : lockfiles,
    );
    code = await command.run();
  } on CommandFailure catch (e) {
    stderr.writeln(e.message);
    code = e.exitCode;
  } finally {
    client.close();
  }
  exit(code);
}
