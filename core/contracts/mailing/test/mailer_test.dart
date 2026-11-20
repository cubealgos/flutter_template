// Test literals (counts, times) and `!` on a value the test just made are
// plain in a test and read worse as named constants.
// A group's body is a list of tests, so it is long by nature.
// ignore_for_file: solid_lints/function_lines_of_code, solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

const _anna = MailRecipient(userId: 'u1', email: 'anna@example.test');

MailMessage _digest({
  Map<String, String>? data,
  String key = 'digest:u1:w40',
  MailLocale locale = MailLocale.en,
  Map<String, String> headers = const <String, String>{},
}) => MailMessage(
  idempotencyKey: key,
  recipient: _anna,
  templateId: 'example_digest',
  locale: locale,
  data: data ?? const <String, String>{'name': 'Anna', 'count': '3'},
  headers: headers,
);

const _transactional = MailTemplate(
  id: 'receipt',
  strings: <MailLocale, MailTemplateStrings>{
    MailLocale.en: MailTemplateStrings(subject: 'Receipt', text: 'Paid.'),
    MailLocale.de: MailTemplateStrings(subject: 'Beleg', text: 'Bezahlt.'),
  },
);

void main() {
  group('idempotency', () {
    test('a retried send never mails twice', () async {
      final mailer = FakeMailer();

      final first = await mailer.send(_digest());
      final second = await mailer.send(_digest());

      expect(mailer.sent, hasLength(1));
      expect(first.replayed, isFalse);
      expect(second.replayed, isTrue);
      expect(second.status, first.status);
    });

    test('concurrent sends with one key reach the transport once', () async {
      final mailer = FakeMailer();

      final results = await Future.wait(<Future<MailDeliveryResult>>[
        for (var i = 0; i < 5; i++) mailer.send(_digest()),
      ]);

      expect(mailer.sent, hasLength(1));
      expect(results.where((r) => !r.replayed), hasLength(1));
    });

    test('a different key is a different send', () async {
      final mailer = FakeMailer();

      await mailer.send(_digest());
      await mailer.send(_digest(key: 'digest:u1:w41'));

      expect(mailer.sent, hasLength(2));
    });

    test('a send that provably did not leave can be retried', () async {
      final mailer = FakeMailer();
      mailer.transport.failWith = const MailNotSentException('no smtp');

      await expectLater(
        mailer.send(_digest()),
        throwsA(isA<MailNotSentException>()),
      );
      mailer.transport.failWith = null;
      final retry = await mailer.send(_digest());

      expect(retry.replayed, isFalse);
      expect(mailer.sent, hasLength(1));
    });

    test('a send of unknown outcome is not retried (at most once)', () async {
      final mailer = FakeMailer();
      mailer.transport.failWith = Exception('connection reset after DATA');

      await expectLater(mailer.send(_digest()), throwsException);
      mailer.transport.failWith = null;
      final retry = await mailer.send(_digest());

      expect(retry.replayed, isTrue);
      expect(retry.status, MailDeliveryStatus.failed);
      expect(mailer.sent, isEmpty);
    });
  });

  group('rendering', () {
    test('renders the locale, falling back to English', () async {
      final mailer = FakeMailer();

      await mailer.send(_digest(locale: MailLocale.de));
      await mailer.send(
        MailMessage(
          idempotencyKey: 'k2',
          recipient: _anna,
          templateId: 'example_digest',
          locale: MailLocale.parse('fr-FR'),
          data: const <String, String>{'name': 'Anna', 'count': '3'},
        ),
      );

      expect(mailer.sent.first.subject, 'Ihre Zusammenfassung: 3 Neuigkeiten');
      expect(mailer.sent[1].subject, 'Your digest: 3 updates');
    });

    test('HTML-escapes values in the html body only, and keeps the subject '
        'on one line', () async {
      final mailer = FakeMailer();

      await mailer.send(
        _digest(
          data: const <String, String>{'name': '<b>A\r\nBcc: x', 'count': '1'},
        ),
      );

      final mail = mailer.sent.single;
      expect(mail.html, contains('&lt;b&gt;'));
      expect(mail.html, isNot(contains('<b>')));
      expect(mail.text, contains('<b>A'));
      expect(mail.subject, isNot(contains('\n')));
    });

    test(
      'missing data and unknown templates are invalid, nothing is stored',
      () async {
        final mailer = FakeMailer();

        await expectLater(
          mailer.send(_digest(data: const <String, String>{'name': 'A'})),
          throwsA(isA<MailInvalidError>()),
        );
        await expectLater(
          mailer.send(
            const MailMessage(
              idempotencyKey: 'k',
              recipient: _anna,
              templateId: 'nope',
            ),
          ),
          throwsA(isA<MailInvalidError>()),
        );
        expect(mailer.store.records, isEmpty);
      },
    );

    test(
      'adds no tracking: no image tag and only the unsubscribe link',
      () async {
        final mailer = FakeMailer();

        await mailer.send(_digest());

        final html = mailer.sent.single.html!;
        expect(html, isNot(contains('<img')));
        expect('href='.allMatches(html), hasLength(1));
      },
    );
  });

  group('unsubscribe headers and suppression', () {
    test('a non-transactional mail carries List-Unsubscribe, the one-click '
        'POST header and a footer link', () async {
      final mailer = FakeMailer();

      await mailer.send(_digest());

      final mail = mailer.sent.single;
      final url = RegExp(
        '<(.*)>',
      ).firstMatch(mail.headers[listUnsubscribeHeader]!)!.group(1)!;
      expect(url, startsWith('https://example.test/unsubscribe?t='));
      expect(
        mail.headers[listUnsubscribePostHeader],
        'List-Unsubscribe=One-Click',
      );
      expect(mail.text, contains(url));
    });

    test('a transactional mail carries neither header nor footer', () async {
      final mailer = FakeMailer(
        catalog: MailCatalog(<MailTemplate>[_transactional]),
      );

      await mailer.send(
        const MailMessage(
          idempotencyKey: 'r1',
          recipient: _anna,
          templateId: 'receipt',
        ),
      );

      expect(mailer.sent.single.headers, isEmpty);
      expect(mailer.sent.single.text, 'Paid.');
    });

    test('a caller cannot set the unsubscribe headers', () async {
      final mailer = FakeMailer();

      await expectLater(
        mailer.send(_digest(headers: const {'list-unsubscribe': '<x>'})),
        throwsA(isA<MailInvalidError>()),
      );
      await expectLater(
        mailer.send(_digest(headers: const {'X-A': 'a\r\nBcc: b'})),
        throwsA(isA<MailInvalidError>()),
      );
    });

    test(
      'an unsubscribed recipient is skipped for that subscription only',
      () async {
        final mailer = FakeMailer(
          catalog: MailCatalog(<MailTemplate>[
            exampleDigestTemplate,
            _transactional,
          ]),
        );
        expect(await mailer.unsubscribe('u1', 'digest'), isTrue);
        expect(await mailer.unsubscribe('u1', 'digest'), isFalse);

        final digest = await mailer.send(_digest());
        final receipt = await mailer.send(
          const MailMessage(
            idempotencyKey: 'r1',
            recipient: _anna,
            templateId: 'receipt',
          ),
        );

        expect(digest.status, MailDeliveryStatus.suppressed);
        expect(receipt.status, MailDeliveryStatus.accepted);
        expect(mailer.sent, hasLength(1));
      },
    );

    test(
      'without unsubscribe links a non-transactional mail is not sent',
      () async {
        final transport = RecordingMailTransport();
        final engine = MailerEngine(
          store: InMemoryMailStore(),
          transport: transport,
          catalog: defaultMailCatalog(),
        );

        await expectLater(
          engine.send(_digest()),
          throwsA(isA<MailNotSentException>()),
        );
        expect(transport.sent, isEmpty);
      },
    );
  });

  group('delivery result', () {
    test('reports a provider rejection', () async {
      final mailer = FakeMailer();
      mailer.transport.outcome = const MailTransportResult(
        status: MailDeliveryStatus.rejected,
        detail: '550 no such user',
      );

      final result = await mailer.send(_digest());

      expect(result.status, MailDeliveryStatus.rejected);
      expect(result.detail, contains('550'));
    });

    test('status refreshes an accepted mail from the provider', () async {
      final mailer = FakeMailer();
      await mailer.send(_digest());
      mailer.transport.refreshed = const MailTransportResult(
        status: MailDeliveryStatus.delivered,
        providerMessageId: 'recorded',
      );

      final status = await mailer.status('digest:u1:w40');

      expect(status!.status, MailDeliveryStatus.delivered);
      expect(await mailer.status('unknown'), isNull);
    });

    test('a bounce is recorded and suppresses the recipient', () async {
      final mailer = FakeMailer();
      await mailer.send(_digest());

      final bounced = await mailer.recordBounce(
        'digest:u1:w40',
        reason: '550 mailbox full',
      );
      final next = await mailer.send(_digest(key: 'digest:u1:w41'));

      expect(bounced!.status, MailDeliveryStatus.bounced);
      expect(
        (await mailer.status('digest:u1:w40'))!.status,
        MailDeliveryStatus.bounced,
      );
      expect(next.status, MailDeliveryStatus.suppressed);
      expect(await mailer.recordBounce('unknown'), isNull);
    });

    test('the delivery record holds no address', () async {
      final mailer = FakeMailer();
      await mailer.send(_digest());

      final record = mailer.store.records.single;

      expect(record.toString(), isNot(contains('anna@')));
      expect(record.userId, 'u1');
    });
  });

  group('MailCatalog', () {
    test('the example catalog is valid and has both locales', () {
      final catalog = defaultMailCatalog();

      final template = catalog.templateFor('example_digest')!;
      expect(template.strings.keys, containsAll(MailLocale.values));
    });

    test('a template without a locale is refused', () {
      expect(
        () => MailCatalog(const <MailTemplate>[
          MailTemplate(
            id: 'x',
            strings: <MailLocale, MailTemplateStrings>{
              MailLocale.en: MailTemplateStrings(subject: 's', text: 't'),
            },
          ),
        ]),
        throwsArgumentError,
      );
    });

    test('a locale whose placeholders differ is refused', () {
      expect(
        () => MailCatalog(const <MailTemplate>[
          MailTemplate(
            id: 'x',
            strings: <MailLocale, MailTemplateStrings>{
              MailLocale.en: MailTemplateStrings(
                subject: 's',
                text: 'Hi {name}',
              ),
              MailLocale.de: MailTemplateStrings(subject: 's', text: 'Hallo'),
            },
          ),
        ]),
        throwsA(
          isA<ArgumentError>().having((e) => '$e', 'message', contains('de')),
        ),
      );
    });

    test('MailLocale.parse takes the language part', () {
      expect(MailLocale.parse('de-AT'), MailLocale.de);
      expect(MailLocale.parse('DE_ch'), MailLocale.de);
      expect(MailLocale.parse(null), MailLocale.en);
      expect(MailLocale.parse('fr'), MailLocale.en);
    });
  });
}
