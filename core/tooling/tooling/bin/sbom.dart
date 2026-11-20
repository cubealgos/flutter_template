import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';
import 'package:tooling/src/sbom_command.dart';

/// `sbom`: generates a CycloneDX 1.6 JSON SBOM for one workspace app's
/// resolved runtime dependency closure. See `sbom_command.dart` for the
/// full description.
///
/// Usage: `fvm dart run tooling:sbom [--app <package>]
/// [--timestamp <ISO-8601>]` (also wired as the `sbom` melos script,
/// which always targets `apps/app` — see root `pubspec.yaml`; pass
/// `-- --app website` through melos for `apps/website`).
Future<void> main(List<String> args) async {
  final SbomRequest request;
  try {
    request = _parseArgs(args);
  } on CommandFailure catch (e) {
    stderr.writeln(e.message);
    exit(usageExitCode);
  }

  final repoRoot = Directory.current.path;
  final licenceClient = PubDevLicenceClient(
    cacheDir: '$repoRoot/.dart_tool/licence_check',
  );
  final int code;
  try {
    code = await SbomCommand(
      repoRoot: repoRoot,
      runner: const SystemProcessRunner(),
      licenceClient: licenceClient,
    ).run(request);
  } finally {
    licenceClient.close();
  }
  exit(code);
}

/// Every flag this CLI accepts takes exactly one value, so the arg index
/// always advances by two (the flag, then its value) per flag consumed.
const int _flagArgWidth = 2;

SbomRequest _parseArgs(List<String> args) {
  var appPackageName = defaultSbomRequest.appPackageName;
  DateTime? timestamp;
  var i = 0;
  while (i < args.length) {
    final arg = args[i];
    switch (arg) {
      case '--app':
        appPackageName = _requireValue(args, i, '--app');
        i += _flagArgWidth;
      case '--timestamp':
        final raw = _requireValue(args, i, '--timestamp');
        timestamp = DateTime.tryParse(raw);
        if (timestamp == null) {
          throw CommandFailure("sbom: invalid --timestamp '$raw'.");
        }
        i += _flagArgWidth;
      default:
        throw CommandFailure(
          'sbom: unknown argument $arg.\n'
          'Usage: sbom [--app <package>] [--timestamp <ISO-8601>]',
        );
    }
  }

  return (
    appPackageName: appPackageName,
    timestamp: timestamp,
    serialNumber: null,
    outputPath: null,
  );
}

String _requireValue(List<String> args, int flagIndex, String flag) {
  if (flagIndex + 1 >= args.length) {
    throw CommandFailure('sbom: $flag needs a value.');
  }

  return args[flagIndex + 1];
}
