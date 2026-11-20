import 'package:tooling/src/command_failure.dart';

/// `web_smoke`'s usage string, shared between [parseWebSmokeArgs] and
/// `WebSmokeCommand` so it's declared exactly once.
const String webSmokeUsage =
    'Usage: web_smoke [--chrome <path>] [--only app|website]';

/// The `--only` values [parseWebSmokeArgs] accepts.
const List<String> webSmokeOnlyValues = <String>['app', 'website'];

/// Parsed `web_smoke` CLI options.
class WebSmokeOptions {
  /// Creates an options value.
  const WebSmokeOptions({this.chrome, this.only});

  /// The `--chrome` flag's value, or `null` if not given (falls through to
  /// `resolveChromeExecutable`'s `CHROME` env var / platform default).
  final String? chrome;

  /// The `--only` flag's value (`app` or `website`), or `null` to run
  /// both — see [webSmokeOnlyValues].
  final String? only;
}

/// Parses `web_smoke`'s CLI [args] into a [WebSmokeOptions], throwing a
/// [CommandFailure] (usage exit code) on an unknown flag, a flag missing
/// its value, or an invalid `--only` value.
///
/// Pure (a `List<String>` in, a [WebSmokeOptions] out — no filesystem,
/// process or environment access), so it's exercised directly by
/// `web_smoke_options_test.dart`.
WebSmokeOptions parseWebSmokeArgs(List<String> args) {
  const knownFlags = {'--chrome', '--only'};
  const flagWidth = 2;
  final values = <String, String>{};
  var i = 0;
  while (i < args.length) {
    final flag = args[i];
    if (!knownFlags.contains(flag)) {
      throw CommandFailure(
        'Unknown flag "$flag". $webSmokeUsage',
        exitCode: usageExitCode,
      );
    }
    if (i + 1 >= args.length) {
      throw CommandFailure(
        '$flag requires a value. $webSmokeUsage',
        exitCode: usageExitCode,
      );
    }
    values[flag] = args[i + 1];
    i += flagWidth;
  }

  final only = values['--only'];
  if (only != null && !webSmokeOnlyValues.contains(only)) {
    throw CommandFailure(
      '--only must be one of ${webSmokeOnlyValues.join(', ')}, got "$only".',
      exitCode: usageExitCode,
    );
  }

  return WebSmokeOptions(chrome: values['--chrome'], only: only);
}
