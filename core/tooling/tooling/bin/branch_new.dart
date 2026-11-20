import 'dart:io';

import 'package:tooling/src/branch_new_command.dart';
import 'package:tooling/src/process_runner.dart';

/// `branch_new <family> <N> <slug>`: creates `.worktrees/<N>/` on a new
/// `<family>/<N>-<slug>` branch and labels GitHub issue `<N>`
/// `status/in-progress`. Must be run from the main checkout.
///
/// Usage: `fvm dart run tooling:branch_new <family> <N> <slug>`
Future<void> main(List<String> args) async {
  final command = BranchNewCommand(runner: const SystemProcessRunner());
  final exitCode = await command.run(args, repoRoot: Directory.current.path);
  exit(exitCode);
}
