import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/licence_bundle_command.dart';
import 'package:tooling/src/process_runner.dart';

/// `licence_bundle`: writes `THIRD_PARTY_LICENSES` for one workspace
/// app's resolved runtime dependency closure. See
/// `licence_bundle_command.dart` for the full description.
///
/// Usage: `fvm dart run tooling:licence_bundle [--app <package>]` (also
/// wired as the `licence-bundle` melos script, which always targets
/// `apps/app` — see root `pubspec.yaml`; pass `-- --app website` through
/// melos for `apps/website`).
Future<void> main(List<String> args) async {
  final LicenceBundleRequest request;
  try {
    request = _parseArgs(args);
  } on CommandFailure catch (e) {
    stderr.writeln(e.message);
    exit(usageExitCode);
  }

  final repoRoot = Directory.current.path;
  final command = LicenceBundleCommand(
    repoRoot: repoRoot,
    runner: const SystemProcessRunner(),
  );
  exit(await command.run(request));
}

/// `--app` takes exactly one value, so the arg index always advances by
/// two (the flag, then its value) per flag consumed.
const int _flagArgWidth = 2;

LicenceBundleRequest _parseArgs(List<String> args) {
  var appPackageName = defaultLicenceBundleRequest.appPackageName;
  var i = 0;
  while (i < args.length) {
    final arg = args[i];
    if (arg != '--app') {
      throw CommandFailure(
        'licence_bundle: unknown argument $arg.\n'
        'Usage: licence_bundle [--app <package>]',
      );
    }
    if (i + 1 >= args.length) {
      throw CommandFailure('licence_bundle: --app needs a value.');
    }
    appPackageName = args[i + 1];
    i += _flagArgWidth;
  }

  return (appPackageName: appPackageName, outputPath: null);
}
