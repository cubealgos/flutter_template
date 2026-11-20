import 'dart:io';

import 'package:tooling/src/gen_fresh_check_command.dart';
import 'package:tooling/src/process_runner.dart';

/// `gen-fresh-check`: clones the current checkout's HEAD into a fresh temp
/// directory, links it to the `.fvmrc`-pinned FVM Flutter SDK, runs
/// `pub get` then `melos run gen` there, and fails unless the result
/// matches HEAD exactly. Runs from the main checkout or any worktree.
///
/// Usage: `fvm dart run tooling:gen_fresh_check`
Future<void> main(List<String> args) async {
  final command = GenFreshCheckCommand(runner: const SystemProcessRunner());
  final exitCode = await command.run(args, repoRoot: Directory.current.path);
  exit(exitCode);
}
