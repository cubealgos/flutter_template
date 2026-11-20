/// Thrown by any stage of the DTCG → Dart pipeline when a token cannot be
/// resolved or converted, naming the offending token path so the error is
/// actionable from the build log alone.
class TokenBuildException implements Exception {
  /// Creates an exception carrying a human-readable [message].
  ///
  /// By convention the message names the token path (or the full alias
  /// chain, for a cycle) that caused the failure.
  const TokenBuildException(this.message);

  /// The human-readable, token-naming description of the failure.
  final String message;

  @override
  String toString() => 'TokenBuildException: $message';
}
