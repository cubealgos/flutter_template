// Test literals are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion

import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dry_run_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fakes/fake_appwrite_admin.dart';

const _settings = MailSettings(
  host: 'smtp.example.test',
  fromEmail: 'noreply@example.test',
  username: 'mailer',
  password: 'hunter2-not-a-real-password',
  unsubscribeBaseUrl: 'https://fn.example.test/unsubscribe',
);

Provisioner _provisioner(FakeAppwriteAdmin admin, {MailSettings? mail}) =>
    Provisioner(
      admin: admin,
      schema: templateSchema,
      mail: mail,
      newSecret: () => 'generated-link-secret',
    );

void main() {
  test('with SMTP settings it creates the Messaging provider and the '
      "api Function's MAIL_* variables, the password and link secret "
      'secret', () async {
    final admin = FakeAppwriteAdmin();

    final report = await _provisioner(admin, mail: _settings).run();

    expect(admin.providers.keys, [mailSmtpProviderId]);
    expect(admin.providers[mailSmtpProviderId]!.host, 'smtp.example.test');
    expect(
      admin.variableValues,
      containsPair('api.MAIL_SMTP_HOST', 'smtp.example.test'),
    );
    expect(
      admin.variableValues,
      containsPair('api.MAIL_FROM', _settings.fromEmail),
    );
    expect(
      admin.variableValues,
      containsPair('api.MAIL_LINK_SECRET', 'generated-link-secret'),
    );
    expect(admin.secretVariables, {
      'api.MAIL_LINK_SECRET',
      'api.MAIL_SMTP_PASSWORD',
    });
    expect(report.notes, isEmpty);
    expect(
      report.changes.join('\n'),
      isNot(contains('hunter2')),
      reason: 'the report never prints a credential',
    );
  });

  test('without settings it skips the provider and the SMTP variables and '
      'says so, but still creates the link secret', () async {
    final admin = FakeAppwriteAdmin();

    final report = await _provisioner(admin).run();

    expect(admin.providers, isEmpty);
    expect(
      admin.variableValues.keys.where((k) => k.contains('MAIL_SMTP')),
      isEmpty,
    );
    expect(admin.variableValues.keys, contains('api.MAIL_LINK_SECRET'));
    expect(report.notes.single, contains('mail: skipped'));
    expect(report.notes.single, contains('MAIL_SMTP_HOST'));
  });

  test(
    'a second run changes nothing and never regenerates the link secret',
    () async {
      final admin = FakeAppwriteAdmin();
      await _provisioner(admin, mail: _settings).run();
      final secret = admin.variableValues['api.MAIL_LINK_SECRET'];

      final again = await Provisioner(
        admin: admin,
        schema: templateSchema,
        mail: _settings,
        newSecret: () => 'a-different-one',
      ).run();

      expect(again.isNoOp, isTrue);
      expect(admin.variableValues['api.MAIL_LINK_SECRET'], secret);
    },
  );

  test('a dry run reports the mail changes and sends none', () async {
    final real = FakeAppwriteAdmin();

    final report = await Provisioner(
      admin: DryRunAdmin(real),
      schema: templateSchema,
      mail: _settings,
    ).run();

    expect(
      report.changes.join('\n'),
      contains('created Messaging SMTP provider "$mailSmtpProviderId"'),
    );
    expect(real.providers, isEmpty);
  });

  test('the generated link secret is long hex and differs per call', () {
    final a = generateMailLinkSecret();

    expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(generateMailLinkSecret(), isNot(a));
  });

  group('MailSettings.fromValues', () {
    test('needs a host and a sender, else mail is not configured', () {
      expect(MailSettings.fromValues({}), isNull);
      expect(MailSettings.fromValues({'MAIL_SMTP_HOST': 'h'}), isNull);
      expect(MailSettings.fromValues({'MAIL_FROM': 'a@b.test'}), isNull);
    });

    test('defaults to port 587 STARTTLS; 465 is implicit TLS', () {
      const base = {'MAIL_SMTP_HOST': 'h', 'MAIL_FROM': 'a@b.test'};

      expect(MailSettings.fromValues(base)!.port, 587);
      expect(MailSettings.fromValues(base)!.implicitTls, isFalse);
      expect(
        MailSettings.fromValues({...base, 'MAIL_SMTP_PORT': '465'})!
            .implicitTls,
        isTrue,
      );
    });

    test('an unusable port is refused loudly', () {
      expect(
        () => MailSettings.fromValues({
          'MAIL_SMTP_HOST': 'h',
          'MAIL_FROM': 'a@b.test',
          'MAIL_SMTP_PORT': 'smtp',
        }),
        throwsFormatException,
      );
    });
  });

  test('BackendEnv reads the MAIL_* values from .env.local, never from '
      'arguments, and only the ones that are set', () {
    final dir = Directory.systemTemp.createTempSync('mail_env_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, '.env.local'))
      ..writeAsStringSync('''
APPWRITE_ENDPOINT=https://e.test/v1
APPWRITE_PROJECT_ID=proj
APPWRITE_API_KEY=key
MAIL_SMTP_HOST=smtp.example.test
MAIL_FROM=noreply@example.test
MAIL_SMTP_USER=
''');

    final env = BackendEnv.load(environment: const {}, dotEnvFile: file);

    expect(env.mail, {
      'MAIL_SMTP_HOST': 'smtp.example.test',
      'MAIL_FROM': 'noreply@example.test',
    });
    expect(MailSettings.fromValues(env.mail), isNotNull);
  });
}
