import 'dart:io';

import 'package:tooling/src/finish_command.dart';
import 'package:tooling/src/process_runner.dart';

/// `finish <N>`: merges the open PR for issue `<N>`, verifies the merge
/// really landed, removes the worktree, fast-forwards the main checkout,
/// runs the verification suite against merged `development` and only then
/// closes the issue. Must be run from the main checkout.
///
/// Usage: `fvm dart run tooling:finish <N>`
Future<void> main(List<String> args) async {
  final command = FinishCommand(runner: const SystemProcessRunner());
  final exitCode = await command.run(args, repoRoot: Directory.current.path);
  exit(exitCode);
}
