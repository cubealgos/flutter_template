import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:paddle_billing/src/signature_verdict.dart';

/// Verifies Paddle's webhook signature.
///
/// From Paddle's documentation
/// (<https://developer.paddle.com/webhooks/signature-verification>): the
/// `Paddle-Signature` header is `ts=<unix timestamp>;h1=<hex>`, and during a
/// secret rotation carries more than one `h1`. The signed payload is the
/// timestamp, a colon, and **the raw body of the request, untouched** (any
/// whitespace change or re-serialisation breaks it), HMAC-SHA256 with the
/// notification destination's secret key, hex encoded. Paddle's SDKs check
/// the timestamp against a tolerance too.
abstract final class PaddleSignature {
  static const int _millisPerSecond = 1000;

  /// The header's name (HTTP header names are case-insensitive).
  static const String headerName = 'paddle-signature';

  /// How far the timestamp may be from now by default: Paddle's SDKs allow
  /// five seconds, which a cold-started Function can exceed, so this is a
  /// minute; the event ID in the ledger is the replay defence either way.
  static const Duration defaultTolerance = Duration(seconds: 60);

  /// Checks [header] against [rawBody] (the exact bytes received) under
  /// [secret], at [now].
  // The header, the body, the secret, the clock and the tolerance are five
  // independent inputs; a parameter object would only rename them.
  // ignore: solid_lints/number_of_parameters
  static SignatureVerdict verify({
    required List<int> rawBody,
    required String? header,
    required String secret,
    required DateTime now,
    Duration tolerance = defaultTolerance,
  }) {
    final parsed = _parse(header);
    if (parsed == null) return SignatureVerdict.malformed;
    final sentAt = DateTime.fromMillisecondsSinceEpoch(
      parsed.timestamp * _millisPerSecond,
      isUtc: true,
    );
    if (now.difference(sentAt).abs() > tolerance) return SignatureVerdict.stale;
    final expected = _hmacHex(secret, parsed.timestamp, rawBody);
    final matches = parsed.signatures.any((h1) => _equal(expected, h1));

    return matches ? SignatureVerdict.valid : SignatureVerdict.mismatch;
  }

  /// The header Paddle would send for [rawBody] at [timestamp] under
  /// [secret]: for tests, which sign payloads themselves.
  static String sign({
    required List<int> rawBody,
    required String secret,
    required DateTime timestamp,
  }) {
    final ts = timestamp.toUtc().millisecondsSinceEpoch ~/ _millisPerSecond;

    return 'ts=$ts;h1=${_hmacHex(secret, ts, rawBody)}';
  }

  static String _hmacHex(String secret, int timestamp, List<int> rawBody) {
    final payload = <int>[...utf8.encode('$timestamp:'), ...rawBody];

    return Hmac(sha256, utf8.encode(secret)).convert(payload).toString();
  }

  static ({int timestamp, List<String> signatures})? _parse(String? header) {
    if (header == null || header.isEmpty) return null;
    int? timestamp;
    final signatures = <String>[];
    for (final part in header.split(';')) {
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      final key = part.substring(0, eq).trim();
      final value = part.substring(eq + 1).trim();
      if (key == 'ts') timestamp = int.tryParse(value);
      if (key == 'h1' && value.isNotEmpty) signatures.add(value);
    }
    if (timestamp == null || signatures.isEmpty) return null;

    return (timestamp: timestamp, signatures: signatures);
  }

  /// Constant-time comparison, so the check leaks nothing about how many
  /// leading characters matched.
  static bool _equal(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return difference == 0;
  }
}
