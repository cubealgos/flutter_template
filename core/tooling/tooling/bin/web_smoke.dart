import 'dart:io';

import 'package:tooling/src/web_smoke_command.dart';

/// `web_smoke`: boots `apps/app`'s and `apps/website`'s built web output
/// in a real headless Chromium and fails on a boot regression (an
/// uncaught exception, a console error, a splash that never clears, or
/// missing localized content) — see `web_smoke_command.dart` for the full
/// description.
///
/// Usage: `fvm dart run tooling:web_smoke [--chrome <path>] [--only
/// app|website]` (also wired as `dart run melos run web-smoke`, which
/// builds both targets first).
Future<void> main(List<String> args) async {
  final command = WebSmokeCommand();
  final exitCode = await command.run(args, repoRoot: Directory.current.path);
  exit(exitCode);
}
