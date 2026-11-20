import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';

/// Reads the Flutter version pinned in `<repoRoot>/.fvmrc`, throwing a
/// [CommandFailure] if the file is missing, not valid JSON, or has no
/// `flutter` version string. Shared by every workflow-tooling command that
/// links a working directory to the same pinned SDK (`branch_new`,
/// `gen_fresh_check`).
String readFvmrcVersion(String repoRoot) {
  final file = File(p.join(repoRoot, '.fvmrc'));
  if (!file.existsSync()) {
    throw CommandFailure(
      '.fvmrc not found at $repoRoot — cannot resolve the pinned Flutter '
      'SDK version.',
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    throw CommandFailure('.fvmrc is not valid JSON: $e');
  }
  final version = decoded is Map ? decoded['flutter'] : null;
  if (version is! String || version.isEmpty) {
    throw CommandFailure('.fvmrc has no "flutter" version string.');
  }

  return version;
}

/// True if `<dir>/.fvm/flutter_sdk/bin/dart` resolves — the on-disk proof
/// that `fvm use --force` actually linked the pinned SDK into [dir].
/// Callers check this rather than trusting `fvm`'s exit code alone (see
/// `branch_new`'s and `gen_fresh_check`'s own verification steps).
bool fvmSdkLinked(String dir) =>
    File(p.join(dir, '.fvm', 'flutter_sdk', 'bin', 'dart')).existsSync();
