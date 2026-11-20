/// A mailer variable the Function lacks or has wrong; the action maps it to a
/// 503 so the operator sees what to set rather than a bare 500.
final class MailNotConfiguredException implements Exception {
  /// Creates the exception.
  const MailNotConfiguredException(this.message);

  /// What is missing.
  final String message;

  @override
  String toString() => 'MailNotConfiguredException: $message';
}
