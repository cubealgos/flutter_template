/// Why an unsubscribe link was refused.
enum InvalidUnsubscribeReason {
  /// Not a token this utility produced.
  malformed,

  /// The signature does not match: forged, altered or signed with another
  /// secret.
  badSignature,

  /// Correctly signed, but past its expiry.
  expired,
}
