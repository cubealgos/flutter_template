/// Paddle answered a call with an error (or not at all).
class PaddleApiException implements Exception {
  /// Creates the exception.
  const PaddleApiException({
    required this.statusCode,
    required this.code,
    required this.detail,
  });

  /// The HTTP status, 0 when there was no answer.
  final int statusCode;

  /// Paddle's `error.code`, or a local one.
  final String code;

  /// Paddle's `error.detail`, for the log (never shown to a user).
  final String detail;

  @override
  String toString() => 'PaddleApiException($statusCode $code): $detail';
}
