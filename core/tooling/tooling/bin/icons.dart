import 'dart:io';

import 'package:tooling/src/icons_command.dart';
import 'package:tooling/src/process_runner.dart';

/// `icons`: regenerates every platform launcher icon and splash screen
/// from `apps/app/assets/icon/icon.png`. See `icons_command.dart` for the
/// full description.
///
/// Usage: `fvm dart run tooling:icons` (or `dart run melos run icons`).
Future<void> main(List<String> args) async {
  final command = IconsCommand(runner: const SystemProcessRunner());
  final exitCode = await command.run(args, repoRoot: Directory.current.path);
  exit(exitCode);
}
