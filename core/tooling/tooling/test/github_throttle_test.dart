import 'dart:io';

import 'package:test/test.dart';
import 'package:tooling/src/github_throttle.dart';

/// How many attempts [GitHubThrottle.guard] makes before a simulated 403
/// finally succeeds, in the "retries ... then returns the eventual
/// success" test below.
const int _attemptsUntil403Succeeds = 3;

/// Same, for the "retries a 429" test below.
const int _attemptsUntil429Succeeds = 2;

/// [GitHubThrottle.maxRetries] used in the "gives up after maxRetries"
/// test below.
const int _maxRetriesForGiveUpTest = 2;

/// A controllable fake clock: [sleeper] both records every requested delay
/// and advances [now] by it, so [GitHubThrottle]'s gap/backoff waits are
/// exercised deterministically — no test here ever waits in real time.
//
// This file is named for the type under test, not for this private fake
// clock (the only class declared here).
// ignore: solid_lints/prefer_match_file_name
class _FakeClock {
  DateTime now = DateTime(2026);
  final List<Duration> sleeps = <Duration>[];

  DateTime read() => now;

  Future<void> sleeper(Duration duration) async {
    sleeps.add(duration);
    now = now.add(duration);
  }
}

ProcessResult _ok() => ProcessResult(0, 0, '', '');
ProcessResult _secondaryRateLimited() => ProcessResult(
  0,
  1,
  '',
  'HTTP 403: You have exceeded a secondary rate '
      'limit. Please wait a few minutes.',
);
ProcessResult _genuineFailure() =>
    ProcessResult(0, 1, '', 'HTTP 404: Not Found');

void main() {
  test('the first call never waits for a gap', () async {
    final clock = _FakeClock();
    final throttle = GitHubThrottle(clock: clock.read, sleeper: clock.sleeper);

    final result = await throttle.guard(() async => _ok());

    expect(result.exitCode, 0);
    expect(clock.sleeps, isEmpty);
  });

  test('spaces two calls at least minGap apart', () async {
    final clock = _FakeClock();
    final throttle = GitHubThrottle(clock: clock.read, sleeper: clock.sleeper);

    await throttle.guard(() async => _ok());
    await throttle.guard(() async => _ok());

    expect(clock.sleeps, [const Duration(seconds: 1)]);
  });

  test('does not wait when enough time already passed', () async {
    final clock = _FakeClock();
    final throttle = GitHubThrottle(clock: clock.read, sleeper: clock.sleeper);

    await throttle.guard(() async => _ok());
    clock.now = clock.now.add(const Duration(seconds: 5));
    await throttle.guard(() async => _ok());

    expect(clock.sleeps, isEmpty);
  });

  test('retries a secondary-rate-limited (403) call with exponential backoff, '
      'then returns the eventual success', () async {
    final clock = _FakeClock();
    final throttle = GitHubThrottle(clock: clock.read, sleeper: clock.sleeper);
    var attempt = 0;

    final result = await throttle.guard(() async {
      attempt++;

      return attempt < _attemptsUntil403Succeeds
          ? _secondaryRateLimited()
          : _ok();
    });

    expect(result.exitCode, 0);
    expect(attempt, _attemptsUntil403Succeeds);
    expect(clock.sleeps, [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
    ], reason: 'each retry doubles the previous backoff');
  });

  test('retries a 429 the same way as a 403', () async {
    final clock = _FakeClock();
    final throttle = GitHubThrottle(clock: clock.read, sleeper: clock.sleeper);
    var attempt = 0;

    final result = await throttle.guard(() async {
      attempt++;

      return attempt < _attemptsUntil429Succeeds
          ? ProcessResult(0, 1, '', 'HTTP 429: too many requests')
          : _ok();
    });

    expect(result.exitCode, 0);
    expect(attempt, _attemptsUntil429Succeeds);
    expect(clock.sleeps, [const Duration(seconds: 1)]);
  });

  test(
    'gives up after maxRetries and returns the last failing result',
    () async {
      final clock = _FakeClock();
      final throttle = GitHubThrottle(
        maxRetries: _maxRetriesForGiveUpTest,
        clock: clock.read,
        sleeper: clock.sleeper,
      );
      var attempt = 0;

      final result = await throttle.guard(() async {
        attempt++;

        return _secondaryRateLimited();
      });

      expect(result.exitCode, 1);
      expect(
        attempt,
        _maxRetriesForGiveUpTest + 1,
        reason: 'the first attempt plus every retry',
      );
      expect(clock.sleeps, [
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ]);
    },
  );

  test('never retries a genuine (non-rate-limit) failure', () async {
    final clock = _FakeClock();
    final throttle = GitHubThrottle(
      minGap: Duration.zero,
      clock: clock.read,
      sleeper: clock.sleeper,
    );
    var attempt = 0;

    final result = await throttle.guard(() async {
      attempt++;

      return _genuineFailure();
    });

    expect(result.exitCode, 1);
    expect(attempt, 1);
    expect(clock.sleeps, isEmpty);
  });

  test('isSecondaryRateLimited recognizes 403, 429 and a rate-limit '
      'message, but not an ordinary error', () {
    expect(isSecondaryRateLimited(_secondaryRateLimited()), isTrue);
    expect(isSecondaryRateLimited(ProcessResult(0, 1, '', 'HTTP 429')), isTrue);
    expect(
      isSecondaryRateLimited(
        ProcessResult(0, 1, '', 'primary rate limit exceeded'),
      ),
      isTrue,
    );
    expect(isSecondaryRateLimited(_genuineFailure()), isFalse);
    expect(isSecondaryRateLimited(_ok()), isFalse);
  });
}
