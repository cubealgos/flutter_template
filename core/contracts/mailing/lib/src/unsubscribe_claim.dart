import 'package:mailing/src/mail_locale.dart';

/// What a verified unsubscribe link says: one person, one subscription.
class UnsubscribeClaim {
  /// Creates a claim.
  const UnsubscribeClaim({
    required this.userId,
    required this.subscription,
    required this.locale,
    required this.expiresAt,
  });

  /// The person the link was made for.
  final String userId;

  /// The one subscription it unsubscribes from.
  final String subscription;

  /// The language of the mail it came from, for the confirmation page.
  final MailLocale locale;

  /// When the link stops working.
  final DateTime expiresAt;
}
