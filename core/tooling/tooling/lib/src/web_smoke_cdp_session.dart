import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tooling/src/command_failure.dart';

/// How long [CdpPageSession.connectToFirstPage] polls `GET /json` for a
/// `page` target before giving up.
const Duration cdpPageTargetTimeout = Duration(seconds: 15);

/// How long a single [CdpPageSession.send] call waits for its matching
/// response before timing out.
const Duration cdpCommandTimeout = Duration(seconds: 15);

/// A single Chrome DevTools Protocol connection to one page target, over a
/// plain `dart:io` [WebSocket] — no `package:webdriver`,
/// `package:puppeteer` or similar; the whole point of driving CDP directly
/// is to add no new heavy dependency (see the issue's own constraint).
///
/// Connects straight to the page target's own `webSocketDebuggerUrl`
/// (found via the browser's `GET /json`) rather than the browser-level
/// socket plus `Target.attachToTarget` flat sessions: every command this
/// tool needs (`Page.navigate`, `Runtime.evaluate`, `Emulation.*`,
/// `Network.*`) is already scoped correctly on a page-level socket, so the
/// extra session-id bookkeeping flat sessions require buys nothing here.
//
// This file is named `web_smoke_cdp_session.dart` (grouping it with this
// tool's other `web_smoke_*.dart` files — see e.g. `web_smoke_chrome_
// process.dart`) rather than `cdp_page_session.dart`, so the exact-name
// match this rule wants doesn't hold even though the class below is this
// file's only real export.
// ignore: solid_lints/prefer_match_file_name
class CdpPageSession {
  CdpPageSession._(this._socket);

  final WebSocket _socket;
  int _nextId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final List<Map<String, dynamic>> _events = [];
  StreamSubscription<dynamic>? _subscription;

  /// Connects to the first `page`-type target Chromium's DevTools HTTP
  /// endpoint at [browserHttpBase] reports (polling `GET /json`, since the
  /// initial `about:blank` tab can take a moment to register after
  /// `ChromeProcess.launch` returns).
  static Future<CdpPageSession> connectToFirstPage(
    String browserHttpBase,
  ) async {
    final targetWsUrl = await _findPageTargetUrl(browserHttpBase);
    final socket = await WebSocket.connect(targetWsUrl);
    final session = CdpPageSession._(socket);
    session._subscription = socket.listen(session._onMessage);

    return session;
  }

  static Future<String> _findPageTargetUrl(String browserHttpBase) async {
    final deadline = DateTime.now().add(cdpPageTargetTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final url = await _tryFindPageTargetUrl(browserHttpBase);
      if (url != null) return url;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw CommandFailure(
      '$browserHttpBase: Chromium never exposed a page DevTools target '
      'within ${cdpPageTargetTimeout.inSeconds}s.',
    );
  }

  static Future<String?> _tryFindPageTargetUrl(String browserHttpBase) async {
    final client = HttpClient();
    try {
      final response = await client
          .getUrl(Uri.parse('$browserHttpBase/json'))
          .then((r) => r.close());
      final body = await response.transform(utf8.decoder).join();
      final targets = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
      for (final target in targets) {
        if (target['type'] == 'page') {
          return target['webSocketDebuggerUrl'] as String?;
        }
      }

      return null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  void _onMessage(dynamic raw) {
    final message = jsonDecode(raw as String) as Map<String, dynamic>;
    final id = message['id'];
    if (id is int) {
      _pending.remove(id)?.complete(message);
    } else if (message['method'] != null) {
      _events.add(message);
    }
  }

  /// Sends a CDP command and returns its response (the full `{"id": ...,
  /// "result": {...}}` message).
  Future<Map<String, dynamic>> send(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _socket.add(
      jsonEncode({
        'id': id,
        'method': method,
        // The suggested `?'params': params` null-aware map entry checks
        // whether the *key* is null, not the value — the analyzer flags
        // it right back as unnecessary once applied, since 'params' is a
        // string literal that's never null. This `if` is the correct
        // conditional-entry form for a nullable *value*.
        // ignore: use_null_aware_elements
        if (params != null) 'params': params,
      }),
    );

    return completer.future.timeout(
      cdpCommandTimeout,
      onTimeout: () => throw CommandFailure('$method timed out.'),
    );
  }

  /// Every event (`{"method": ..., "params": ...}`) received so far,
  /// oldest first — an immutable snapshot safe to hand to
  /// `collectBootIssues`/`hasSuccessfulResponse` (pure functions, no live
  /// dependency on this session).
  List<Map<String, dynamic>> eventsSoFar() => List.unmodifiable(_events);

  /// Closes the underlying websocket.
  Future<void> close() async {
    await _subscription?.cancel();
    await _socket.close();
  }
}
