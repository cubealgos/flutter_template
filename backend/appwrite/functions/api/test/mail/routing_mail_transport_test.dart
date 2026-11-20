// Test names are not the file name.
// ignore_for_file: solid_lints/prefer_match_file_name

import 'package:api/src/mail/dry_run_mail_transport.dart';
import 'package:api/src/mail/routing_mail_transport.dart';
import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

const _anna = MailRecipient(userId: 'u1', email: 'anna@example.test');

RenderedMail _mail({Map<String, String> headers = const {}}) => RenderedMail(
  idempotencyKey: 'k',
  recipient: _anna,
  templateId: 't',
  locale: MailLocale.en,
  subject: 's',
  text: 't',
  headers: headers,
);

void main() {
  test('mail with headers goes to SMTP, mail without to Messaging', () async {
    final messaging = RecordingMailTransport();
    final smtp = RecordingMailTransport();
    final router = RoutingMailTransport(messaging: messaging, smtp: smtp);

    await router.send(_mail());
    await router.send(_mail(headers: {'List-Unsubscribe': '<x>'}));

    expect(messaging.sent, hasLength(1));
    expect(smtp.sent, hasLength(1));
    expect(smtp.sent.single.headers, isNotEmpty);
  });

  test('a mail whose transport is not configured is "not sent"', () async {
    const router = RoutingMailTransport();

    await expectLater(
      router.send(_mail(headers: {'List-Unsubscribe': '<x>'})),
      throwsA(
        isA<MailNotSentException>().having(
          (e) => e.message,
          'message',
          contains('MAIL_SMTP'),
        ),
      ),
    );
    await expectLater(
      router.send(_mail()),
      throwsA(isA<MailNotSentException>()),
    );
  });

  test('the dry-run transport records nothing and says so', () async {
    final result = await const DryRunMailTransport().send(_mail());

    expect(result.status, MailDeliveryStatus.accepted);
    expect(result.detail, contains('dry run'));
  });
}
