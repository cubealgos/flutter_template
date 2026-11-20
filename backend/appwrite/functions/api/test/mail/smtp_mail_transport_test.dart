// Test literals are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/prefer_match_file_name

import 'dart:io';

import 'package:api/src/mail/smtp_mail_transport.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

import '../support/fake_smtp_server.dart';

const _anna = MailRecipient(userId: 'u1', email: 'anna@example.test');

RenderedMail _digest() => const RenderedMail(
  idempotencyKey: 'k',
  recipient: _anna,
  templateId: 'example_digest',
  locale: MailLocale.en,
  subject: 'Your digest: 3 updates',
  text: 'Hello Anna',
  html: '<p>Hello Anna</p>',
  subscription: 'digest',
  headers: <String, String>{
    'List-Unsubscribe': '<https://example.test/unsubscribe?t=abc.def>',
    'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
  },
);

SmtpMailTransport _transport(FakeSmtpServer server) => SmtpMailTransport(
  server: SmtpServer(
    InternetAddress.loopbackIPv4.address,
    port: server.port,
    allowInsecure: true,
  ),
  from: 'noreply@example.test',
  fromName: 'Template',
);

/// A started server that is closed when the test ends.
Future<FakeSmtpServer> _server({String rcptReply = '250 ok'}) async {
  final server = await FakeSmtpServer.start(rcptReply: rcptReply);
  addTearDown(server.close);

  return server;
}

void main() {
  test('puts List-Unsubscribe and List-Unsubscribe-Post on the wire and '
      'reports accepted', () async {
    final server = await _server();

    final result = await _transport(server).send(_digest());

    expect(result.status, MailDeliveryStatus.accepted);
    final wire = server.messages.single.toLowerCase();
    expect(
      wire,
      contains(
        'list-unsubscribe: <https://example.test/unsubscribe?t=abc.def>',
      ),
    );
    expect(wire, contains('list-unsubscribe-post: list-unsubscribe=one-click'));
    expect(wire, contains('your digest: 3 updates'));
    expect(wire, isNot(contains('<img')));
  });

  test(
    'a 5xx at RCPT is a permanent rejection with the server reason',
    () async {
      final server = await _server(rcptReply: '550 no such user');

      final result = await _transport(server).send(_digest());

      expect(result.status, MailDeliveryStatus.rejected);
      expect(result.detail, contains('550'));
      expect(server.messages, isEmpty);
    },
  );

  test('a 4xx is "not sent", so the engine may retry', () async {
    final server = await _server(rcptReply: '450 try later');

    await expectLater(
      _transport(server).send(_digest()),
      throwsA(isA<MailNotSentException>()),
    );
  });

  test('an unreachable server is "not sent", not an unknown outcome', () async {
    final server = await _server();
    final port = server.port;
    await server.close();
    final transport = SmtpMailTransport(
      server: SmtpServer(
        InternetAddress.loopbackIPv4.address,
        port: port,
        allowInsecure: true,
      ),
      from: 'noreply@example.test',
    );

    await expectLater(
      transport.send(_digest()),
      throwsA(isA<MailNotSentException>()),
    );
  });

  test('works under the engine: one send reaches the server once even when '
      'retried', () async {
    final server = await _server();
    final engine = MailerEngine(
      store: InMemoryMailStore(),
      transport: _transport(server),
      catalog: defaultMailCatalog(),
      links: UnsubscribeLinks(
        secret: 's',
        endpoint: Uri.parse('https://example.test/unsubscribe'),
      ),
    );
    const message = MailMessage(
      idempotencyKey: 'digest:u1:w40',
      recipient: _anna,
      templateId: 'example_digest',
      data: <String, String>{'name': 'Anna', 'count': '3'},
    );

    await engine.send(message);
    final retry = await engine.send(message);

    expect(retry.replayed, isTrue);
    expect(server.messages, hasLength(1));
    expect(
      server.messages.single.toLowerCase(),
      contains('list-unsubscribe: <https://example.test/unsubscribe?t='),
    );
  });
}
