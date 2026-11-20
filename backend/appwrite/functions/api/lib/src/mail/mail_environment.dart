import 'package:api/src/action_context.dart';
import 'package:api/src/mail/appwrite_mail_store.dart';
import 'package:api/src/mail/dry_run_mail_transport.dart';
import 'package:api/src/mail/mail_not_configured_exception.dart';
import 'package:api/src/mail/messaging_gateway.dart';
import 'package:api/src/mail/messaging_mail_transport.dart';
import 'package:api/src/mail/routing_mail_transport.dart';
import 'package:api/src/mail/smtp_mail_transport.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailing/mailing.dart';

/// The Function variable choosing the transport: `auto` (default: SMTP for
/// mail with headers, Appwrite Messaging for the rest), `messaging`, `smtp`
/// or `dry` (record, send nothing).
const String mailTransportEnvKey = 'MAIL_TRANSPORT';

/// The secret (a Function variable, secret) the unsubscribe links are signed
/// with; `appwrite_tool` generates it on the first provision. Without it no
/// link can be made or honoured.
const String mailLinkSecretEnvKey = 'MAIL_LINK_SECRET';

/// The URL a mail's unsubscribe link points at: the `api` Function's
/// execution domain plus `/unsubscribe`. Without it a non-transactional mail
/// is not sent.
const String mailUnsubscribeBaseUrlEnvKey = 'MAIL_UNSUBSCRIBE_BASE_URL';

/// How many days an unsubscribe link works (default 60).
const String mailLinkTtlDaysEnvKey = 'MAIL_LINK_TTL_DAYS';

/// SMTP host for direct sending.
const String mailSmtpHostEnvKey = 'MAIL_SMTP_HOST';

/// SMTP port (default 587, STARTTLS; 465 means implicit TLS).
const String mailSmtpPortEnvKey = 'MAIL_SMTP_PORT';

/// SMTP user.
const String mailSmtpUserEnvKey = 'MAIL_SMTP_USER';

/// SMTP password (a secret variable).
const String mailSmtpPasswordEnvKey = 'MAIL_SMTP_PASSWORD';

/// The sender address.
const String mailFromEnvKey = 'MAIL_FROM';

/// The sender's display name.
const String mailFromNameEnvKey = 'MAIL_FROM_NAME';

/// How long `mail_deliveries` rows are kept, in whole days.
const String mailDeliveryRetentionEnvKey = 'MAIL_DELIVERY_RETENTION_DAYS';

/// The implicit-TLS SMTP port.
const int _implicitTlsPort = 465;

/// The submission port.
const int _submissionPort = 587;

/// The signed-link utility for [environment], or null when
/// [mailLinkSecretEnvKey] is unset. [needBaseUrl] true (sending) also
/// requires [mailUnsubscribeBaseUrlEnvKey]; verifying a link does not.
UnsubscribeLinks? unsubscribeLinksFrom(
  Map<String, String> environment, {
  required bool needBaseUrl,
  DateTime Function()? clock,
}) {
  final secret = environment[mailLinkSecretEnvKey];
  if (secret == null || secret.isEmpty) return null;
  final base = environment[mailUnsubscribeBaseUrlEnvKey];
  if (needBaseUrl && (base == null || base.isEmpty)) return null;
  final days = int.tryParse(environment[mailLinkTtlDaysEnvKey] ?? '');

  return UnsubscribeLinks(
    secret: secret,
    endpoint: Uri.parse(base ?? 'https://invalid.invalid/unsubscribe'),
    ttl: days == null || days < 1
        ? defaultUnsubscribeTtl
        : Duration(days: days),
    clock: clock,
  );
}

/// The direct SMTP transport for [environment], or null without
/// [mailSmtpHostEnvKey] and [mailFromEnvKey].
SmtpMailTransport? smtpTransportFrom(Map<String, String> environment) {
  final host = environment[mailSmtpHostEnvKey];
  final from = environment[mailFromEnvKey];
  if (host == null || host.isEmpty || from == null || from.isEmpty) {
    return null;
  }
  final port =
      int.tryParse(environment[mailSmtpPortEnvKey] ?? '') ?? _submissionPort;
  final user = environment[mailSmtpUserEnvKey];

  return SmtpMailTransport(
    server: SmtpServer(
      host,
      port: port,
      ssl: port == _implicitTlsPort,
      username: user == null || user.isEmpty ? null : user,
      password: environment[mailSmtpPasswordEnvKey],
    ),
    from: from,
    fromName: environment[mailFromNameEnvKey],
  );
}

/// The transport the Function's variables select (see
/// [mailTransportEnvKey]).
MailTransport transportFrom(
  ActionContext context, {
  MessagingGateway? messaging,
}) {
  final environment = context.environment;
  final mode = environment[mailTransportEnvKey] ?? 'auto';
  final viaMessaging = MessagingMailTransport(
    messaging ?? AppwriteMessagingGateway(context.client),
  );
  final viaSmtp = smtpTransportFrom(environment);

  return switch (mode) {
    'dry' => const DryRunMailTransport(),
    'messaging' => RoutingMailTransport(messaging: viaMessaging),
    'smtp' => RoutingMailTransport(smtp: viaSmtp),
    'auto' => RoutingMailTransport(messaging: viaMessaging, smtp: viaSmtp),
    _ => throw const MailNotConfiguredException(
      '$mailTransportEnvKey must be auto, messaging, smtp or dry.',
    ),
  };
}

/// The mailer an action run uses: the engine over Appwrite tables, the
/// configured transport and the example [catalog] (a clone passes its own).
MailerEngine mailerFor(ActionContext context, {MailCatalog? catalog}) =>
    MailerEngine(
      store: AppwriteMailStore(
        client: context.client,
        databaseId: templateSchema.databaseId,
      ),
      transport: transportFrom(context),
      catalog: catalog ?? defaultMailCatalog(),
      links: unsubscribeLinksFrom(context.environment, needBaseUrl: true),
    );
