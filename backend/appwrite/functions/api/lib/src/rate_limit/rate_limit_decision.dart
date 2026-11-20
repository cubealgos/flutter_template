/// The answer of `RateLimiter.check`.
class RateLimitDecision {
  /// Creates a decision.
  const RateLimitDecision({
    required this.allowed,
    required this.remaining,
    required this.retryAfter,
  });

  /// Whether this call is within the limit (and was counted).
  final bool allowed;

  /// Calls still allowed in this window after this one.
  final int remaining;

  /// How long until the window resets and a refused caller may retry.
  final Duration retryAfter;
}
