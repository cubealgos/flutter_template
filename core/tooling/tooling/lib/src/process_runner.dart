import 'dart:io';

/// Abstraction over external process execution, used by every workflow-
/// tooling command (`branch_new`, `finish`, `branch_lint`) so tests can
/// inject a fake instead of shelling out to a real `git`/`gh` binary or
/// hitting the network.
abstract class ProcessRunner {
  /// Runs [executable] with [arguments], optionally in [workingDirectory],
  /// and returns its result the way `dart:io`'s [Process.run] does.
  ///
  /// [environment], if given, is merged on top of the parent process'
  /// environment (never replacing it — see [Process.run]'s
  /// `includeParentEnvironment`, left at its default `true`).
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

/// The [ProcessRunner] every `bin/*.dart` entry point uses in production:
/// shells out to the real OS process via [Process.run].
class SystemProcessRunner implements ProcessRunner {
  /// Creates a process runner backed by the real operating system.
  const SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }
}
