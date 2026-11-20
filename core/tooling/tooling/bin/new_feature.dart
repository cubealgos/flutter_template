import 'dart:io';

import 'package:tooling/src/new_feature_command.dart';

/// `new_feature <path>`: scaffolds a feature under `apps/app/lib/features/`
/// (view, controller, model, mobile layout), its tests, and its route.
///
/// Usage: `fvm dart run tooling:new_feature settings/notifications`
Future<void> main(List<String> args) async {
  final exitCode = await NewFeatureCommand().run(
    args,
    repoRoot: Directory.current.path,
  );
  exit(exitCode);
}
