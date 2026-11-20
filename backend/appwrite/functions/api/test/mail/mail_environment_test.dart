// Test literals are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/mail/mail_environment.dart';
import 'package:api/src/mail/mail_not_configured_exception.dart';
import 'package:api/src/mail/messaging_gateway.dart';
import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

import '../support/test_context.dart';

void main() {
  group('unsubscribeLinksFrom', () {
    test('needs the secret; sending also needs the base URL', () {
      expect(unsubscribeLinksFrom({}, needBaseUrl: false), isNull);
      expect(
        unsubscribeLinksFrom({mailLinkSecretEnvKey: 's'}, needBaseUrl: true),
        isNull,
      );
      expect(
        unsubscribeLinksFrom({mailLinkSecretEnvKey: 's'}, needBaseUrl: false),
        isNotNull,
      );
    });

    test(
      'builds a link on the configured base URL with the configured ttl',
      () {
        final links = unsubscribeLinksFrom({
          mailLinkSecretEnvKey: 's',
          mailUnsubscribeBaseUrlEnvKey: 'https://x.test/unsubscribe',
          mailLinkTtlDaysEnvKey: '7',
        }, needBaseUrl: true)!;

        expect(links.ttl, const Duration(days: 7));
        expect(
          links
              .linkFor(
                userId: 'u',
                subscription: 'digest',
                locale: MailLocale.en,
              )
              .toString(),
          startsWith('https://x.test/unsubscribe?t='),
        );
      },
    );
  });

  test('SMTP needs a host and a sender; 465 means implicit TLS', () {
    expect(smtpTransportFrom({mailSmtpHostEnvKey: 'smtp.test'}), isNull);
    final transport = smtpTransportFrom({
      mailSmtpHostEnvKey: 'smtp.test',
      mailFromEnvKey: 'noreply@x.test',
      mailSmtpPortEnvKey: '465',
      mailSmtpUserEnvKey: 'u',
      mailSmtpPasswordEnvKey: 'p',
    })!;

    expect(transport.server.ssl, isTrue);
    expect(transport.server.username, 'u');
    expect(transport.from, 'noreply@x.test');
    expect(
      smtpTransportFrom({
        mailSmtpHostEnvKey: 'smtp.test',
        mailFromEnvKey: 'a@x.test',
      })!.server.port,
      587,
    );
  });

  test('an unknown MAIL_TRANSPORT is refused, dry is allowed', () {
    expect(
      () => transportFrom(testContext(environment: {mailTransportEnvKey: 'x'})),
      throwsA(isA<MailNotConfiguredException>()),
    );
    expect(
      transportFrom(
        testContext(environment: {mailTransportEnvKey: 'dry'}),
        messaging: _NoGateway(),
      ),
      isNotNull,
    );
  });
}

class _NoGateway implements MessagingGateway {
  @override
  Future<MessagingMessage> createEmail(MessagingEmail email) =>
      throw UnimplementedError();

  @override
  Future<MessagingMessage> getMessage(String messageId) =>
      throw UnimplementedError();
}
