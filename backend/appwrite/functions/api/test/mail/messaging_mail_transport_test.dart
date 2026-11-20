// Test literals are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/mail/messaging_gateway.dart';
import 'package:api/src/mail/messaging_mail_transport.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

const _anna = MailRecipient(userId: 'u1', email: 'anna@example.test');

RenderedMail _mail({String? html, Map<String, String> headers = const {}}) =>
    RenderedMail(
      idempotencyKey: 'k1',
      recipient: _anna,
      templateId: 't',
      locale: MailLocale.en,
      subject: 'Hello',
      text: 'text',
      html: html,
      headers: headers,
    );

class _FakeGateway implements MessagingGateway {
  final List<MessagingEmail> created = <MessagingEmail>[];
  final Map<String, MessagingMessage> messages = <String, MessagingMessage>{};
  AppwriteException? failWith;
  String status = 'processing';
  int delivered = 0;

  @override
  Future<MessagingMessage> createEmail(MessagingEmail email) async {
    final failure = failWith;
    if (failure != null) throw failure;
    created.add(email);
    final message = MessagingMessage(
      id: email.messageId,
      status: status,
      deliveredTotal: delivered,
    );
    messages[email.messageId] = message;

    return message;
  }

  @override
  Future<MessagingMessage> getMessage(String messageId) async =>
      messages[messageId]!;
}

void main() {
  test('sends to the user by ID, HTML when there is html, accepted while '
      'Messaging is still processing', () async {
    final gateway = _FakeGateway();

    final result = await MessagingMailTransport(
      gateway,
    ).send(_mail(html: '<p>x</p>'));

    expect(result.status, MailDeliveryStatus.accepted);
    expect(gateway.created.single.userId, 'u1');
    expect(gateway.created.single.html, isTrue);
    expect(gateway.created.single.content, '<p>x</p>');
    expect(gateway.created.single.messageId, hasLength(32));
  });

  test(
    'refuses a mail that needs headers: Messaging cannot set them',
    () async {
      final gateway = _FakeGateway();

      await expectLater(
        MessagingMailTransport(
          gateway,
        ).send(_mail(headers: {'List-Unsubscribe': '<x>'})),
        throwsA(isA<MailNotSentException>()),
      );
      expect(gateway.created, isEmpty);
    },
  );

  test('refresh maps sent, failed and processing', () async {
    final gateway = _FakeGateway();
    final transport = MessagingMailTransport(gateway);
    await transport.send(_mail());
    final id = gateway.created.single.messageId;

    gateway.messages[id] = MessagingMessage(
      id: id,
      status: 'sent',
      deliveredTotal: 1,
    );
    expect((await transport.refresh(id))!.status, MailDeliveryStatus.delivered);
    gateway.messages[id] = MessagingMessage(
      id: id,
      status: 'failed',
      deliveredTotal: 0,
      errors: const ['mailbox full'],
    );
    final failed = (await transport.refresh(id))!;
    expect(failed.status, MailDeliveryStatus.failed);
    expect(failed.detail, 'mailbox full');
    gateway.messages[id] = MessagingMessage(
      id: id,
      status: 'sent',
      deliveredTotal: 0,
    );
    expect((await transport.refresh(id))!.status, MailDeliveryStatus.failed);
  });

  test('a 409 (the message ID exists) reads the existing message instead of '
      'creating a second', () async {
    final gateway = _FakeGateway();
    final transport = MessagingMailTransport(gateway);
    await transport.send(_mail());
    gateway.failWith = AppwriteException('exists', 409, 'general_conflict');

    final again = await transport.send(_mail());

    expect(again.status, MailDeliveryStatus.accepted);
    expect(gateway.created, hasLength(1));
  });

  test(
    'a 4xx from Appwrite means nothing was sent; a 5xx is unknown',
    () async {
      final gateway = _FakeGateway()
        ..failWith = AppwriteException('no provider', 400, 'provider_missing');
      final transport = MessagingMailTransport(gateway);

      await expectLater(
        transport.send(_mail()),
        throwsA(isA<MailNotSentException>()),
      );
      gateway.failWith = AppwriteException('boom', 500);
      await expectLater(
        transport.send(_mail()),
        throwsA(isA<AppwriteException>()),
      );
    },
  );
}
