import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mailing/src/invalid_unsubscribe_link_error.dart';
import 'package:mailing/src/invalid_unsubscribe_reason.dart';
import 'package:mailing/src/mail_locale.dart';
import 'package:mailing/src/unsubscribe_claim.dart';

/// How long an unsubscribe link works unless told otherwise. Long, because a
/// recipient may act on an old mail; a newer mail always carries a fresh link.
const Duration defaultUnsubscribeTtl = Duration(days: 60);

/// Signed, expiring one-click unsubscribe links.
///
/// A link is `<endpoint>?t=<token>` and the token is
/// `base64url(payload) + "." + base64url(HMAC-SHA-256(secret, domain +
/// payload))` over a JSON payload of the **user ID, the subscription, the
/// locale and the expiry**: one person and one subscription, nothing a
/// caller can widen. The HMAC under a secret that lives in a Function
/// variable is the approach `RateLimiter` in `api` uses for its keys; the
/// `domain` prefix keeps a token from ever being valid for another purpose
/// under the same secret.
/// [verify] checks the signature (in constant time) *before* it parses the
/// payload, then the expiry.
///
/// Rotating the secret invalidates every outstanding link, which is the
/// revocation lever.
class UnsubscribeLinks {
  /// Creates the utility. [endpoint] is the HTTPS URL of the unsubscribe
  /// handler; the token goes in its `t` query parameter. [clock] is the time
  /// source.
  UnsubscribeLinks({
    required String secret,
    required this.endpoint,
    DateTime Function()? clock,
    this.ttl = defaultUnsubscribeTtl,
  }) : _secret = utf8.encode(secret),
       _clock = clock ?? DateTime.now {
    if (secret.isEmpty) {
      throw ArgumentError.value(secret, 'secret', 'must not be empty');
    }
  }

  /// The handler's URL.
  final Uri endpoint;

  /// How long a new link works.
  final Duration ttl;

  final List<int> _secret;
  final DateTime Function() _clock;

  static const int _msPerSecond = 1000;
  static const int _tokenParts = 2;

  static const String _domain = 'mailing.unsubscribe.v1\n';

  /// The query parameter carrying the token.
  static const String tokenParameter = 't';

  /// The link for [userId] and [subscription], written in [locale].
  Uri linkFor({
    required String userId,
    required String subscription,
    required MailLocale locale,
  }) => endpoint.replace(
    queryParameters: <String, String>{
      ...endpoint.queryParameters,
      tokenParameter: tokenFor(
        userId: userId,
        subscription: subscription,
        locale: locale,
      ),
    },
  );

  /// The bare token for [userId] and [subscription].
  String tokenFor({
    required String userId,
    required String subscription,
    required MailLocale locale,
  }) {
    final expiresAt =
        _clock().toUtc().add(ttl).millisecondsSinceEpoch ~/ _msPerSecond;
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode(<String, Object>{
              'u': userId,
              's': subscription,
              'l': locale.tag,
              'e': expiresAt,
            }),
          ),
        )
        .replaceAll('=', '');

    return '$payload.${_signature(payload)}';
  }

  /// The claim [token] carries.
  ///
  /// Throws [InvalidUnsubscribeLinkError] when it is malformed, its
  /// signature is wrong or it has expired. Nothing is read from an unsigned
  /// payload.
  UnsubscribeClaim verify(String token) {
    final parts = token.split('.');
    if (parts.length != _tokenParts || parts.any((part) => part.isEmpty)) {
      throw const InvalidUnsubscribeLinkError(
        InvalidUnsubscribeReason.malformed,
      );
    }
    final payload = parts.first;
    if (!_constantTimeEquals(parts[1], _signature(payload))) {
      throw const InvalidUnsubscribeLinkError(
        InvalidUnsubscribeReason.badSignature,
      );
    }
    final claim = _decode(payload);
    if (!claim.expiresAt.isAfter(_clock().toUtc())) {
      throw const InvalidUnsubscribeLinkError(InvalidUnsubscribeReason.expired);
    }

    return claim;
  }

  UnsubscribeClaim _decode(String payload) {
    try {
      final json =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(payload))),
              )
              as Map<String, dynamic>;

      return UnsubscribeClaim(
        userId: json['u'] as String,
        subscription: json['s'] as String,
        locale: MailLocale.parse(json['l'] as String?),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (json['e'] as int) * _msPerSecond,
          isUtc: true,
        ),
      );
    } on Object {
      throw const InvalidUnsubscribeLinkError(
        InvalidUnsubscribeReason.malformed,
      );
    }
  }

  String _signature(String payload) => base64Url
      .encode(
        Hmac(sha256, _secret).convert(utf8.encode('$_domain$payload')).bytes,
      )
      .replaceAll('=', '');

  /// Compares without stopping at the first difference.
  static bool _constantTimeEquals(String a, String b) {
    var diff = a.length ^ b.length;
    final length = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return diff == 0;
  }
}
