/// The result of checking a `Paddle-Signature` header.
enum SignatureVerdict {
  /// Genuine and fresh.
  valid,

  /// The header is missing or not `ts=<unix>;h1=<hex>`.
  malformed,

  /// The timestamp is further from now than the tolerance allows: a replay of
  /// an old capture, or a clock that is far off.
  stale,

  /// No `h1` matches the body under the secret: forged, or the body was
  /// altered, or it was re-serialised.
  mismatch,
}
