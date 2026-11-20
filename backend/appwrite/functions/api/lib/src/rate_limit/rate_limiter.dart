import 'dart:convert';

import 'package:api/src/action_context.dart';
import 'package:api/src/rate_limit/appwrite_rate_limit_store.dart';
import 'package:api/src/rate_limit/rate_limit_decision.dart';
import 'package:api/src/rate_limit/rate_limit_store.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:crypto/crypto.dart';

/// The Function variable holding the secret the keys are hashed with. Set it
/// (a long random string) on the `api` Function before using the limiter;
/// without it `RateLimiter.forContext` refuses rather than store a
/// guessable hash.
const String rateLimitSecretEnvKey = 'RATE_LIMIT_SECRET';

/// A fixed-window rate limiter for unauthenticated actions, with no
/// third-party service.
///
/// Call [check] with a `scope` (what is being limited: `'review_sign_in'`), a
/// `key` (an IP address, a host) and a `limit` per `window`. The key is never
/// stored: only an HMAC-SHA-256 of `scope` and `key` under
/// [rateLimitSecretEnvKey], so a leaked table reveals no address and the
/// hash can't be brute-forced over the small IPv4 space without the secret.
///
/// **Counting without compare-and-set.** TablesDB can't increment atomically,
/// so a hit is a row unique on (key hash, window, hit number): [check] starts
/// from the current count and tries hit `n + 1`, `n + 2`, ... until an insert
/// wins or the limit is passed. Concurrent callers can never share a number,
/// so the limit is exact; the cost is up to `limit` inserts in a burst, so
/// keep limits small (tens, not thousands).
///
/// **Retention.** A hit row lives to the end of its window and is then
/// useless; `HousekeepingJob` deletes expired rows hourly, so a key is
/// retained for at most `window` + one hour. Nothing else is stored.
class RateLimiter {
  /// Creates a limiter over [store], hashing keys with [secret]; [clock] is
  /// the time source.
  RateLimiter({
    required this.store,
    required String secret,
    DateTime Function()? clock,
  }) : _secret = utf8.encode(secret),
       _clock = clock ?? DateTime.now {
    if (secret.isEmpty) {
      throw ArgumentError.value(secret, 'secret', 'must not be empty');
    }
  }

  /// A limiter for an action run: Appwrite tables, and the secret from the
  /// Function's environment. Throws [StateError] if the secret is not set.
  factory RateLimiter.forContext(ActionContext context) {
    final secret = context.environment[rateLimitSecretEnvKey];
    if (secret == null || secret.isEmpty) {
      throw StateError('$rateLimitSecretEnvKey is not set on the Function.');
    }

    return RateLimiter(
      store: AppwriteRateLimitStore(
        client: context.client,
        databaseId: templateSchema.databaseId,
      ),
      secret: secret,
    );
  }

  /// The persistence.
  final RateLimitStore store;

  final List<int> _secret;
  final DateTime Function() _clock;

  /// The hash stored for [key] under [scope]: lowercase hex, 64 characters.
  String keyHashOf(String scope, String key) =>
      Hmac(sha256, _secret).convert(utf8.encode('$scope\n$key')).toString();

  /// Counts one call of [key] under [scope] and says whether it is within
  /// [limit] calls per [window].
  Future<RateLimitDecision> check({
    required String scope,
    required String key,
    required int limit,
    required Duration window,
  }) async {
    if (limit < 1 || window <= Duration.zero) {
      throw ArgumentError('limit and window must be positive.');
    }
    final now = _clock().toUtc();
    final windowMs = window.inMilliseconds;
    final start = now.millisecondsSinceEpoch ~/ windowMs * windowMs;
    final end = DateTime.fromMillisecondsSinceEpoch(
      start + windowMs,
      isUtc: true,
    );
    final hash = keyHashOf(scope, key);
    final retryAfter = end.difference(now);

    var hit = await store.hitsIn(hash, start) + 1;
    while (hit <= limit) {
      if (await store.tryTake(hash, start, hit, end)) {
        return RateLimitDecision(
          allowed: true,
          remaining: limit - hit,
          retryAfter: retryAfter,
        );
      }
      hit++;
    }

    return RateLimitDecision(
      allowed: false,
      remaining: 0,
      retryAfter: retryAfter,
    );
  }
}
