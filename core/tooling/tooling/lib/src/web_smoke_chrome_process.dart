import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tooling/src/command_failure.dart';

/// How long [ChromeProcess.launch] waits for Chromium to print its
/// DevTools websocket URL before giving up.
const Duration chromeStartupTimeout = Duration(seconds: 20);

/// A headless Chromium/Chrome subprocess, launched with a fresh
/// `--user-data-dir` and a fixed `--lang`, exposing the browser-level
/// DevTools Protocol websocket URL it printed on startup.
///
/// Launched fresh per (target, locale) pair by `WebSmokeCommand` rather
/// than reused across locales — simpler and fully isolated (no stale
/// `navigator.language`/cache state from a previous run) at the cost of a
/// few extra seconds per pair, negligible next to a `flutter build web`.
//
// This file is named `web_smoke_chrome_process.dart` (grouping it with
// this tool's other `web_smoke_*.dart` files) rather than
// `chrome_process.dart`, so the exact-name match this rule wants doesn't
// hold even though the class below is this file's only real export.
// ignore: solid_lints/prefer_match_file_name
class ChromeProcess {
  ChromeProcess._(this._process, this.browserWebSocketUrl);

  final Process _process;

  /// The `ws://…/devtools/browser/<id>` URL Chromium printed on stderr.
  final String browserWebSocketUrl;

  /// The DevTools HTTP endpoint's base URL (`http://host:port`), derived
  /// from [browserWebSocketUrl] — `GET $httpBase/json` lists page targets.
  String get httpBase {
    final uri = Uri.parse(browserWebSocketUrl);

    return 'http://${uri.host}:${uri.port}';
  }

  /// Launches [executable] headless, with `Accept-Language`/UI locale set
  /// to [lang] and a fresh, isolated [userDataDir]. `--no-sandbox`
  /// `--disable-dev-shm-usage` are always passed: this only ever renders
  /// this repo's own build output, never untrusted content, and CI runs
  /// the container as root, where Chromium's setuid sandbox refuses to
  /// start at all without `--no-sandbox`.
  static Future<ChromeProcess> launch({
    required String executable,
    required String lang,
    required Directory userDataDir,
  }) async {
    final process = await Process.start(executable, [
      '--headless=new',
      '--disable-gpu',
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--no-first-run',
      '--no-default-browser-check',
      '--remote-debugging-port=0',
      '--user-data-dir=${userDataDir.path}',
      '--lang=$lang',
      'about:blank',
    ]);
    unawaited(process.stdout.drain<void>());
    final wsUrl = await _awaitDevToolsUrl(process);

    return ChromeProcess._(process, wsUrl);
  }

  static Future<String> _awaitDevToolsUrl(Process process) {
    final completer = Completer<String>();
    final pattern = RegExp(r'DevTools listening on (ws://\S+)');
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final match = pattern.firstMatch(line);
          if (match != null && !completer.isCompleted) {
            completer.complete(match.group(1));
          }
        });

    return completer.future.timeout(
      chromeStartupTimeout,
      onTimeout: () => throw CommandFailure(
        '${process.pid}: Chromium never printed a DevTools websocket URL '
        'within ${chromeStartupTimeout.inSeconds}s.',
      ),
    );
  }

  /// Terminates the browser process and waits for it to exit.
  Future<void> close() async {
    _process.kill();
    await _process.exitCode;
  }
}
