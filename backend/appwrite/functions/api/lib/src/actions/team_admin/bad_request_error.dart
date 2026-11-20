/// A request the Function can't act on: a missing or mistyped argument, or
/// an unknown action. Answered with HTTP 400, never a `TeamError`.
class BadRequestError implements Exception {
  /// Creates the error with a developer-facing [message].
  const BadRequestError(this.message);

  /// What was wrong with the request.
  final String message;
}
