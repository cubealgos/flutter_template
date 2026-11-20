import 'dart:io';

/// Sleeps for [duration] — overridden in tests to advance a fake clock
/// instead of waiting in real time.
typedef ThrottleSleeper = Future<void> Function(Duration duration);

/// The current time — overridden in tests alongside [ThrottleSleeper] so
/// [GitHubThrottle] can be driven deterministically, with no real delay.
typedef ThrottleClock = DateTime Function();

/// Throttles GitHub API calls made through `gh` that create content
/// (labels, comments, issue edits, merges): every call routed through
/// [guard] is spaced at least [minGap] apart from the previous one, and a
/// call whose `gh` invocation fails with a secondary-rate-limit response
/// (HTTP 403/429 — `gh` prints the status in its stderr and exits
/// non-zero) is retried with exponential backoff, up to [maxRetries]
/// times, instead of surfacing the failure immediately.
///
/// GitHub's secondary rate limit is 80 requests/minute and 500/hour;
/// spacing content-creating calls at least a second apart keeps
/// `branch_new`/`finish` well under both even on a repo with many labels
/// to apply.
class GitHubThrottle {
  /// Creates a throttle. [clock]/[sleeper] default to the real wall clock
  /// and a real delay; tests inject fakes (typically a mutable fake clock
  /// that [sleeper] itself advances) so a test never actually waits.
  GitHubThrottle({
    this.minGap = const Duration(seconds: 1),
    this.maxRetries = 4,
    ThrottleClock clock = DateTime.now,
    ThrottleSleeper sleeper = Future<void>.delayed,
  })
    // Neither can be an initializing formal (`this._clock`/`this._sleeper`):
    // that would make each private field's name the external named-parameter
    // name too, which a caller outside this library (every test) couldn't
    // pass.
    // ignore: prefer_initializing_formals
    : _clock = clock,
       // Same reason as _clock above.
       // ignore: prefer_initializing_formals
       _sleeper = sleeper;

  /// The minimum time between the end of one throttled call and the start
  /// of the next.
  final Duration minGap;

  /// How many times a secondary-rate-limited call is retried before its
  /// last (still-failing) [ProcessResult] is returned to the caller.
  final int maxRetries;

  final ThrottleClock _clock;
  final ThrottleSleeper _sleeper;

  DateTime? _lastCallEndedAt;

  /// Runs one `gh` invocation via [invoke], enforcing [minGap] since the
  /// previous call this throttle guarded and retrying with exponential
  /// backoff (`minGap * 2^attempt`) while [isSecondaryRateLimited] holds
  /// and fewer than [maxRetries] retries have been spent.
  Future<ProcessResult> guard(Future<ProcessResult> Function() invoke) async {
    var attempt = 0;
    while (true) {
      await _waitForGap();
      final result = await invoke();
      _lastCallEndedAt = _clock();
      final limited = result.exitCode != 0 && isSecondaryRateLimited(result);
      if (!limited || attempt >= maxRetries) {
        return result;
      }
      await _sleeper(minGap * (1 << attempt));
      attempt++;
    }
  }

  Future<void> _waitForGap() async {
    final last = _lastCallEndedAt;
    if (last == null) return;

    final elapsed = _clock().difference(last);
    if (elapsed < minGap) {
      await _sleeper(minGap - elapsed);
    }
  }
}

/// Whether [result] (a failed `gh` invocation) looks like GitHub's
/// secondary rate limit (HTTP 403/429) rather than a genuine,
/// non-retryable error — `gh` surfaces the HTTP status and GitHub's own
/// message text in stderr (occasionally stdout, for a `gh api` JSON
/// payload) on an API error.
bool isSecondaryRateLimited(ProcessResult result) {
  final text = '${result.stdout}\n${result.stderr}'.toLowerCase();

  return text.contains('403') ||
      text.contains('429') ||
      text.contains('rate limit');
}
