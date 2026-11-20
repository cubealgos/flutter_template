import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:tooling/src/command_failure.dart';

/// The HTTP status a successful request returns.
const int _httpOk = 200;

/// HTTP status a service answers when rate limiting; retried.
const int _httpTooManyRequests = 429;

/// First status of the 5xx range; every one of them is retried.
const int _httpServerErrorFrom = 500;

/// Attempts per request before the run fails.
const int _defaultMaxAttempts = 5;

/// Base of the exponential backoff: attempt n waits base * 2^(n-1) plus jitter.
const Duration _defaultBaseDelay = Duration(milliseconds: 500);

/// Per-request timeout.
const Duration _requestTimeout = Duration(seconds: 30);

/// One keep-alive [http.Client] serving every request of a run, with
/// retries for transient failures (handshake/socket/TLS errors, timeouts,
/// 429, 5xx) using exponential backoff plus jitter. A 4xx other than 429
/// fails at once. Shared by `PubDevLicenceClient` and `OsvClient` so both
/// network-bound gates behave the same on a flaky connection.
///
/// The client, the wait (`delay`), the jitter source and the log are
/// injectable so tests never touch the network or sleep. (Transient retries
/// are capped at `maxAttempts`, backoff starts at `baseDelay`.)
class RetryingHttp {
  /// Creates a helper for [service] (a human name used in messages, e.g.
  /// `pub.dev`). Pass [httpClient] to inject one in tests, otherwise a real
  /// one is created; call [close] when the run is over.
  RetryingHttp({
    required this.service,
    http.Client? httpClient,
    Future<void> Function(Duration)? delay,
    Random? random,
    void Function(String)? log,
    this._maxAttempts = _defaultMaxAttempts,
    this._baseDelay = _defaultBaseDelay,
  }) : _client = httpClient ?? http.Client(),
       _delay = delay ?? Future<void>.delayed,
       _random = random ?? Random(),
       _log = log ?? stderr.writeln;

  /// The service's human name, used in every message.
  final String service;

  final http.Client _client;
  final int _maxAttempts;
  final Duration _baseDelay;
  final Future<void> Function(Duration) _delay;
  final Random _random;
  final void Function(String) _log;

  /// Closes the underlying HTTP client, ending the keep-alive connection.
  void close() => _client.close();

  /// Runs [request] against the shared client until it returns 200, retrying
  /// transient failures. [subject] names what the request is about (a
  /// package, a batch) and [uri] is shown in the failure message. Throws
  /// [CommandFailure] on a non-transient failure or once attempts run out.
  Future<http.Response> send(
    String subject,
    Uri uri,
    Future<http.Response> Function(http.Client client) request,
  ) async {
    for (var attempt = 1; ; attempt++) {
      String reason;
      try {
        final response = await request(_client).timeout(_requestTimeout);
        if (response.statusCode == _httpOk) return response;
        if (!_isTransientStatus(response.statusCode)) {
          throw CommandFailure(
            '$service returned ${response.statusCode} for $subject ($uri).',
          );
        }
        reason = 'HTTP ${response.statusCode}';
      } on CommandFailure {
        rethrow;
      } on Exception catch (e) {
        if (!_isTransientError(e)) {
          throw CommandFailure('$service request for $subject failed: $e');
        }
        reason = '$e';
      }
      if (attempt >= _maxAttempts) {
        throw CommandFailure(
          '$service request for $subject failed after $attempt '
          'attempts: $reason',
        );
      }
      final backoff = _baseDelay * (1 << (attempt - 1));
      final jitter = Duration(
        milliseconds: _random.nextInt(backoff.inMilliseconds + 1),
      );
      final wait = backoff + jitter;
      _log(
        '$service request for $subject failed ($reason); retry '
        '$attempt/${_maxAttempts - 1} in ${wait.inMilliseconds} ms',
      );
      await _delay(wait);
    }
  }

  static bool _isTransientStatus(int status) =>
      status == _httpTooManyRequests || status >= _httpServerErrorFrom;

  static bool _isTransientError(Exception e) =>
      e is HandshakeException ||
      e is TlsException ||
      e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException;
}
