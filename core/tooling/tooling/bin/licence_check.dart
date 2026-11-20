import 'dart:io';

import 'package:tooling/src/licence_check_command.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';

/// `licence_check`: walks every `source: hosted` package in the
/// workspace's `pubspec.lock` plus `core/architecture/mvc_lints/pubspec.lock`,
/// checks each package's pub.dev-reported licence against the allow/deny
/// policy in `licence_policy.dart` and the keyed exceptions in
/// `tool/licence-exceptions.yaml`, and exits non-zero if any is denied.
///
/// Usage: `fvm dart run tooling:licence_check` (repo root or a worktree —
/// resolves lockfiles relative to [Directory.current]).
Future<void> main(List<String> _) async {
  final repoRoot = Directory.current.path;
  final client = PubDevLicenceClient(
    cacheDir: '$repoRoot/.dart_tool/licence_check',
  );
  final int code;
  try {
    code = await LicenceCheckCommand(repoRoot: repoRoot, client: client).run();
  } finally {
    client.close();
  }
  exit(code);
}
