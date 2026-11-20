import 'dart:convert';
import 'dart:io';

import 'package:tooling/src/process_runner.dart';

/// A [ProcessRunner] that answers every call for [executable] with
/// [stdout] (JSON-encoding it if it isn't already a [String]) and exits
/// `0`, and throws on any other executable — used by
/// `dependency_graph_test.dart`, `sbom_command_test.dart` and
/// `licence_bundle_command_test.dart` to fake `dart pub deps --json`
/// without a real pub resolution.
class FakeDartProcessRunner implements ProcessRunner {
  /// Creates a runner that answers [executable] with [stdout].
  FakeDartProcessRunner(this.executable, Object stdout)
    : stdout = stdout is String ? stdout : jsonEncode(stdout);

  /// The one executable this runner answers.
  final String executable;

  /// The stdout every call returns.
  final String stdout;

  /// Every argument list seen so far, in call order.
  final List<List<String>> calls = <List<String>>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (executable != this.executable) {
      throw StateError(
        'FakeDartProcessRunner: unexpected call to $executable.',
      );
    }
    calls.add(arguments);

    return ProcessResult(0, 0, stdout, '');
  }
}

/// A [ProcessRunner] simulating `dart pub deps --json` exiting non-zero
/// (e.g. an unresolved workspace) — used by `dependency_graph_test.dart`.
class FailingDartProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async => ProcessResult(0, 1, '', 'pub deps failed');
}
