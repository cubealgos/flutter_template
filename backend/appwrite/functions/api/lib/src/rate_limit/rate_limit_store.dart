/// What `RateLimiter` needs from a backend: counting hits of one key in one
/// window, and taking one numbered hit atomically.
abstract interface class RateLimitStore {
  /// How many hits [keyHash] has in the window starting at [windowStart].
  Future<int> hitsIn(String keyHash, int windowStart);

  /// Takes hit number [hit] (from 1) of the window. True if this call got
  /// it, false if another already had: a store holds (key, window, hit)
  /// unique, which is what makes the count safe without a compare-and-set.
  /// The row is retained until [expiresAt] (the window's end), no longer.
  Future<bool> tryTake(
    String keyHash,
    int windowStart,
    int hit,
    DateTime expiresAt,
  );
}
