// Test literals (limits, status codes) and `!` on a value the test just made
// are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/actions/send_example_mail/example_mail_sender.dart';
import 'package:api/src/rate_limit/rate_limiter.dart';
import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

import '../../support/in_memory_stores.dart';

const _anna = MailRecipient(userId: 'u1', email: 'anna@example.test');

ExampleMailSender _sender(
  FakeMailer mailer, {
  RateLimiter? limiter,
  MailRecipient? recipient = _anna,
}) => ExampleMailSender(
  mailer: mailer,
  lookup: (_) async => recipient,
  limiter:
      limiter ??
      RateLimiter(store: InMemoryRateLimitStore(), secret: 'rate-secret'),
);

void main() {
  test('mails the caller the localised example digest, end to end', () async {
    final mailer = FakeMailer();

    final response = await _sender(
      mailer,
    ).handle('u1', {'requestId': 'r1', 'locale': 'de'});

    expect(response.statusCode, 200);
    expect(response.body['status'], 'accepted');
    final mail = mailer.sent.single;
    expect(mail.recipient.email, 'anna@example.test');
    expect(mail.subject, 'Ihre Zusammenfassung: 3 Neuigkeiten');
    expect(mail.headers['List-Unsubscribe'], startsWith('<https://'));
    expect(mail.headers['List-Unsubscribe-Post'], 'List-Unsubscribe=One-Click');
    expect(mail.html, isNot(contains('<img')));
  });

  test('a retried request mails once', () async {
    final mailer = FakeMailer();
    final sender = _sender(mailer);

    await sender.handle('u1', {'requestId': 'r1'});
    final retry = await sender.handle('u1', {'requestId': 'r1'});

    expect(retry.body['replayed'], isTrue);
    expect(mailer.sent, hasLength(1));
  });

  test('an unsubscribed caller is not mailed', () async {
    final mailer = FakeMailer();
    await mailer.unsubscribe('u1', 'digest');

    final response = await _sender(mailer).handle('u1', {'requestId': 'r1'});

    expect(response.body['status'], 'suppressed');
    expect(mailer.sent, isEmpty);
  });

  test('refuses a bad requestId, a missing verified email and a missing '
      'limiter', () async {
    final mailer = FakeMailer();

    for (final id in <Object?>[null, '', 'a b', 'x' * 65, 7]) {
      expect(
        (await _sender(mailer).handle('u1', {'requestId': id})).statusCode,
        400,
      );
    }
    expect(
      (await _sender(
        mailer,
        recipient: null,
      ).handle('u1', {'requestId': 'r1'})).statusCode,
      403,
    );
    expect(
      (await ExampleMailSender(
        mailer: mailer,
        lookup: (_) async => _anna,
        limiter: null,
      ).handle('u1', {'requestId': 'r1'})).statusCode,
      503,
    );
    expect(mailer.sent, isEmpty);
  });

  test('limits the calls per user and hour', () async {
    final mailer = FakeMailer();
    final sender = _sender(mailer);

    final codes = <int>[
      for (var i = 0; i < exampleMailLimit + 1; i++)
        (await sender.handle('u1', {'requestId': 'r$i'})).statusCode,
    ];

    expect(codes, [200, 200, 200, 200, 200, 429]);
    expect(mailer.sent, hasLength(exampleMailLimit));
  });

  test('a mail that could not leave is a 503 and may be retried', () async {
    final mailer = FakeMailer();
    mailer.transport.failWith = const MailNotSentException('no smtp');
    final sender = _sender(mailer);

    final first = await sender.handle('u1', {'requestId': 'r1'});
    mailer.transport.failWith = null;
    final retry = await sender.handle('u1', {'requestId': 'r1'});

    expect(first.statusCode, 503);
    expect(retry.statusCode, 200);
    expect(mailer.sent, hasLength(1));
  });
}
