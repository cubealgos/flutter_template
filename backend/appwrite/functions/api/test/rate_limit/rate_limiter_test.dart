// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/rate_limit/rate_limiter.dart';
import 'package:test/test.dart';

import '../support/in_memory_stores.dart';
import '../support/test_context.dart';

const _window = Duration(minutes: 10);

RateLimiter _limiter(InMemoryRateLimitStore store, DateTime Function() clock) =>
    RateLimiter(store: store, secret: 'pepper', clock: clock);

void main() {
  test('allows up to the limit in a window, then refuses', () async {
    final now = DateTime.utc(2026, 1, 1, 0, 3);
    final limiter = _limiter(InMemoryRateLimitStore(), () => now);

    final decisions = [
      for (var i = 0; i < 4; i++)
        await limiter.check(
          scope: 's',
          key: '1.2.3.4',
          limit: 3,
          window: _window,
        ),
    ];

    expect(decisions.map((d) => d.allowed), [true, true, true, false]);
    expect(decisions.map((d) => d.remaining), [2, 1, 0, 0]);
    expect(decisions.last.retryAfter, const Duration(minutes: 7));
  });

  test('concurrent callers never exceed the limit', () async {
    final now = DateTime.utc(2026);
    final store = InMemoryRateLimitStore();
    final limiter = _limiter(store, () => now);

    final decisions = await Future.wait([
      for (var i = 0; i < 10; i++)
        limiter.check(scope: 's', key: 'k', limit: 4, window: _window),
    ]);

    expect(decisions.where((d) => d.allowed), hasLength(4));
    expect(store.rows, hasLength(4));
  });

  test(
    'the next window starts fresh; other keys and scopes are independent',
    () async {
      var now = DateTime.utc(2026, 1, 1, 0, 1);
      final limiter = _limiter(InMemoryRateLimitStore(), () => now);
      Future<bool> hit(String scope, String key) async => (await limiter.check(
        scope: scope,
        key: key,
        limit: 1,
        window: _window,
      )).allowed;

      expect(await hit('s', 'a'), isTrue);
      expect(await hit('s', 'a'), isFalse);
      expect(await hit('s', 'b'), isTrue);
      expect(await hit('t', 'a'), isTrue);
      now = DateTime.utc(2026, 1, 1, 0, 11);
      expect(await hit('s', 'a'), isTrue);
    },
  );

  test('stores only a keyed hash with an expiry at the window end, never the '
      'address', () async {
    final now = DateTime.utc(2026, 1, 1, 0, 3);
    final store = InMemoryRateLimitStore();
    final limiter = _limiter(store, () => now);

    await limiter.check(
      scope: 's',
      key: '203.0.113.9',
      limit: 5,
      window: _window,
    );

    final stored = store.rows.keys.single;
    expect(stored, isNot(contains('203.0.113.9')));
    expect(stored.split('|').first, limiter.keyHashOf('s', '203.0.113.9'));
    expect(limiter.keyHashOf('s', 'x'), matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(store.rows.values.single, DateTime.utc(2026, 1, 1, 0, 10));
    expect(
      RateLimiter(store: store, secret: 'other').keyHashOf('s', 'x'),
      isNot(limiter.keyHashOf('s', 'x')),
      reason: 'the hash depends on the secret',
    );
  });

  test('refuses an empty secret, and forContext needs the variable', () {
    expect(
      () => RateLimiter(store: InMemoryRateLimitStore(), secret: ''),
      throwsArgumentError,
    );
    expect(() => RateLimiter.forContext(testContext()), throwsStateError);
    expect(
      RateLimiter.forContext(
        testContext(environment: {rateLimitSecretEnvKey: 'x'}),
      ),
      isA<RateLimiter>(),
    );
  });

  test('rejects a non-positive limit or window', () {
    final limiter = _limiter(InMemoryRateLimitStore(), DateTime.now);

    expect(
      () => limiter.check(scope: 's', key: 'k', limit: 0, window: _window),
      throwsArgumentError,
    );
    expect(
      () =>
          limiter.check(scope: 's', key: 'k', limit: 1, window: Duration.zero),
      throwsArgumentError,
    );
  });
}
