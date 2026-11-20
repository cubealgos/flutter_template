import 'dart:io';

import 'package:api/src/mail/appwrite_mail_store.dart';
import 'package:api/src/mail/messaging_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:mailing/mailing.dart';

/// Sends through **Appwrite Messaging** (the SMTP provider `appwrite_tool`
/// creates from `.env.local`).
///
/// **What Messaging can and cannot do** (read from `dart_appwrite` 29.0.0's
/// `Messaging.createEmail`): it takes a subject, content, an
/// html flag, recipients (users, topics, targets), cc/bcc, attachments and a
/// schedule, and **nothing for custom headers**, so it cannot set
/// `List-Unsubscribe`; a mail that needs headers goes through
/// `SmtpMailTransport` instead (see `RoutingMailTransport`). The mail goes to
/// the recipient user's own email target, so no address is passed. It reports
/// a message's `status` (processing, sent, failed), `deliveredTotal` and
/// `deliveryErrors`, and **no bounce**. There is no plain-text alternative
/// part: an HTML mail goes as HTML only.
///
/// The Messaging message ID is derived from the idempotency key, so a send
/// that raced past the store's claim still cannot create a second message
/// (Appwrite answers 409 and the existing one is read).
class MessagingMailTransport implements MailTransport {
  /// Creates the transport over [gateway].
  MessagingMailTransport(this.gateway);

  static const int _messageIdLength = 32;

  /// Appwrite Messaging.
  final MessagingGateway gateway;

  @override
  Future<MailTransportResult> send(RenderedMail mail) async {
    if (mail.headers.isNotEmpty) {
      throw const MailNotSentException(
        'Appwrite Messaging cannot set mail headers; send mail with headers '
        'through SMTP.',
      );
    }
    final messageId = AppwriteMailStore.hashOf(
      mail.idempotencyKey,
    ).substring(0, _messageIdLength);
    final html = mail.html;
    try {
      return _resultOf(
        await gateway.createEmail(
          MessagingEmail(
            messageId: messageId,
            userId: mail.recipient.userId,
            subject: mail.subject,
            content: html ?? mail.text,
            html: html != null,
          ),
        ),
      );
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) {
        return _resultOf(await gateway.getMessage(messageId));
      }
      final code = e.code ?? 0;
      if (code >= HttpStatus.badRequest &&
          code < HttpStatus.internalServerError) {
        throw MailNotSentException(
          'Appwrite Messaging refused the mail (${e.type ?? code}): '
          '${e.message}',
        );
      }
      rethrow;
    }
  }

  @override
  Future<MailTransportResult?> refresh(String providerMessageId) async =>
      _resultOf(await gateway.getMessage(providerMessageId));

  static MailTransportResult _resultOf(MessagingMessage message) {
    final errors = message.errors.isEmpty ? null : message.errors.join('; ');
    switch (message.status) {
      case 'sent':
        return message.deliveredTotal > 0
            ? MailTransportResult(
                status: MailDeliveryStatus.delivered,
                providerMessageId: message.id,
              )
            : MailTransportResult(
                status: MailDeliveryStatus.failed,
                providerMessageId: message.id,
                detail: errors ?? 'Messaging delivered to no one.',
              );
      case 'failed':
        return MailTransportResult(
          status: MailDeliveryStatus.failed,
          providerMessageId: message.id,
          detail: errors ?? 'Messaging reports the message failed.',
        );
      default:
        return MailTransportResult(
          status: MailDeliveryStatus.accepted,
          providerMessageId: message.id,
        );
    }
  }
}
