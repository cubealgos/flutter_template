/// A transport could not hand the mail off at all (no configuration, a
/// refused connection, a failed login): **nothing was sent**, so the engine
/// releases the claim and a retry with the same key may send. A transport
/// throws anything else only when the mail may have left, and the engine then
/// keeps the claim (at-most-once).
final class MailNotSentException implements Exception {
  /// Creates the exception.
  const MailNotSentException(this.message);

  /// Why nothing was sent.
  final String message;

  @override
  String toString() => 'MailNotSentException: $message';
}
