/// A Paddle payload that is not what Paddle documents. Thrown only after the
/// signature was verified, so it names a Paddle-side change, not an attack.
class PaddleParseException implements Exception {
  /// Creates the exception.
  const PaddleParseException(this.message);

  /// What was wrong.
  final String message;

  @override
  String toString() => 'PaddleParseException: $message';
}
