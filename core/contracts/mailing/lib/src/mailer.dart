import 'package:mailing/src/mail_delivery_result.dart';
import 'package:mailing/src/mail_message.dart';

/// Sends the app's own email. Server-side only: it runs inside `api` actions
/// and jobs, never in a client.
abstract interface class Mailer {
  /// Renders and sends [message]. A second call with the same
  /// `MailMessage.idempotencyKey` never sends again and returns the first
  /// call's result with `replayed` set. A non-transactional mail to an
  /// unsubscribed or bounced recipient is not sent (`suppressed`).
  ///
  /// Throws `MailInvalidError` for an unknown template or missing data, and
  /// lets a transport failure propagate (see `MailNotSentException`).
  Future<MailDeliveryResult> send(MailMessage message);

  /// The stored result for [idempotencyKey], refreshed from the provider when
  /// it can report (Appwrite Messaging), or null when no such send exists.
  Future<MailDeliveryResult?> status(String idempotencyKey);

  /// Records that the mail of [idempotencyKey] bounced (from a provider's
  /// bounce webhook, a clone's `hooks` handler): marks it `bounced` and
  /// suppresses its recipient. Returns the new result, or null for an
  /// unknown key. Plain SMTP and Appwrite Messaging do not report an
  /// asynchronous bounce themselves.
  Future<MailDeliveryResult?> recordBounce(
    String idempotencyKey, {
    String? reason,
  });

  /// Unsubscribes [userId] from [subscription]; true when that was new.
  Future<bool> unsubscribe(String userId, String subscription);
}
