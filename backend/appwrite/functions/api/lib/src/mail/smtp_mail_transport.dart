import 'dart:async';
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailing/mailing.dart' as mailing;

/// Sends one built [Message] over [server]; `package:mailer`'s `send` in
/// production, replaceable in tests.
typedef SmtpSend = Future<Object?> Function(Message message, SmtpServer server);

Future<Object?> _defaultSend(Message message, SmtpServer server) =>
    send(message, server, timeout: const Duration(seconds: 20));

/// Sends **directly over SMTP** with `package:mailer` (MIT), the one path
/// that can set `List-Unsubscribe` and `List-Unsubscribe-Post` (Appwrite
/// Messaging cannot; see `MessagingMailTransport`).
///
/// **Delivery result.** SMTP answers synchronously: a `250` is `accepted`, a
/// `5xx` is `rejected` (permanent), a `4xx` or a failed connection or login
/// is `MailNotSentException` (a retry may send). SMTP can never say
/// `delivered`, and an asynchronous bounce reaches no one here: a clone wires
/// its provider's bounce webhook (the reserved `hooks` Function) to
/// `Mailer.recordBounce`.
///
/// **No tracking.** The message is built from the rendered text and html as
/// they are; nothing is added or rewritten.
class SmtpMailTransport implements mailing.MailTransport {
  /// Creates the transport. [from] is the sender address, [fromName] its
  /// display name; [sender] is replaceable for tests.
  SmtpMailTransport({
    required this.server,
    required this.from,
    this.fromName,
    SmtpSend? sender,
  }) : _send = sender ?? _defaultSend;

  /// The SMTP server and its credentials.
  final SmtpServer server;

  /// The sender address.
  final String from;

  /// The sender's display name, if any.
  final String? fromName;

  final SmtpSend _send;

  @override
  Future<mailing.MailTransportResult> send(mailing.RenderedMail mail) async {
    final message = Message()
      ..from = Address(from, fromName ?? '')
      ..recipients.add(mail.recipient.email)
      ..subject = mail.subject
      ..text = mail.text
      ..html = mail.html
      ..headers = <String, dynamic>{...mail.headers};
    try {
      await _send(message, server);

      return const mailing.MailTransportResult(
        status: mailing.MailDeliveryStatus.accepted,
      );
    } on SmtpClientCommunicationException catch (e) {
      return _classify(e);
    } on SmtpClientAuthenticationException catch (e) {
      throw mailing.MailNotSentException('SMTP login failed: ${e.message}');
    } on SmtpUnsecureException catch (e) {
      throw mailing.MailNotSentException('SMTP is not secure: ${e.message}');
    } on SmtpMessageValidationException catch (e) {
      throw mailing.MailNotSentException('Invalid mail: ${e.message}');
    } on SmtpNoGreetingException catch (e) {
      throw mailing.MailNotSentException('SMTP server is silent: ${e.message}');
    } on SocketException catch (e) {
      if (_neverConnected(e)) {
        throw mailing.MailNotSentException('SMTP unreachable: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<mailing.MailTransportResult?> refresh(
    String providerMessageId,
  ) async => null;

  /// A server reply that is not 2xx: 5xx is a permanent refusal, 4xx a
  /// "try later", and both mean the server did not take the mail. Anything
  /// without a reply code is unknown and rethrown (at most once).
  mailing.MailTransportResult _classify(SmtpClientCommunicationException e) {
    final reply = RegExp(
      r'Response from server: <?\s*(\d{3})',
    ).firstMatch(e.message)?.group(1);
    if (reply == null) throw e;
    if (reply.startsWith('5')) {
      return mailing.MailTransportResult(
        status: mailing.MailDeliveryStatus.rejected,
        detail: e.message.split('\n').last,
      );
    }
    if (reply.startsWith('4')) {
      throw mailing.MailNotSentException(
        'SMTP asked to retry later: ${e.message.split('\n').last}',
      );
    }
    throw e;
  }

  static bool _neverConnected(SocketException e) {
    final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();

    return text.contains('refused') ||
        text.contains('failed host lookup') ||
        text.contains('unreachable');
  }
}
