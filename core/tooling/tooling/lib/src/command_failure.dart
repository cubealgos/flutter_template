import 'package:tooling/src/github_client.dart';

/// The exit code returned for a usage error (wrong argument count) —
/// matches the BSD/Unix `sysexits.h` convention (`EX_USAGE`).
const int usageExitCode = 64;

/// Thrown by a workflow-tooling command step to abort the command with a
/// human-readable message and an exit code.
///
/// Each command's `run()` entry point delegates to [runCatchingFailures],
/// which catches exactly one of these (or a [GitHubRequestFailure]) at the
/// top level, prints its message and returns the matching exit code — every
/// validation or git/GitHub step below it throws instead of threading
/// `if (...) return` checks back up through the call stack, which keeps
/// each step's own cyclomatic complexity low.
class CommandFailure implements Exception {
  /// Creates a failure with [message] and an optional [exitCode] (default:
  /// the generic "refused" exit code, `1`).
  CommandFailure(this.message, {this.exitCode = 1});

  /// The message printed to stderr.
  final String message;

  /// The process exit code this command should return.
  final int exitCode;

  @override
  String toString() => message;
}

/// Runs [body], converting a thrown [CommandFailure] or
/// [GitHubRequestFailure] into `(exit code, printed via err)` instead of
/// letting either escape as an uncaught exception. Shared by every
/// workflow-tooling command's `run()` so the try/catch shell isn't
/// duplicated across them.
Future<int> runCatchingFailures(
  Future<void> Function() body,
  void Function(String) err,
) async {
  try {
    await body();

    return 0;
  } on CommandFailure catch (e) {
    err(e.message);

    return e.exitCode;
  } on GitHubRequestFailure catch (e) {
    err('GitHub API request failed: $e');

    return 1;
  }
}
