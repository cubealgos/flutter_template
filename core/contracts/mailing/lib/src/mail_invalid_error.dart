/// A send the caller got wrong: an unknown template, missing data, a bad key.
final class MailInvalidError implements Exception {
  /// Creates the error.
  const MailInvalidError(this.message);

  /// A developer-facing description, not localized.
  final String message;

  @override
  String toString() => 'MailInvalidError: $message';
}
