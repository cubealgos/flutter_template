import 'dart:io';

import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/rename_command.dart';

/// `rename`: renames the whole cloned template. See `rename_command.dart`
/// for the full description.
///
/// Usage: `fvm dart run tooling:rename --name acme_notes --org de.example
/// --display "Acme Notes"` (full flag reference in `rename_command.dart`'s
/// usage string).
Future<void> main(List<String> args) async {
  final command = RenameCommand(runner: const SystemProcessRunner());
  final exitCode = await command.run(args, repoRoot: Directory.current.path);
  exit(exitCode);
}
