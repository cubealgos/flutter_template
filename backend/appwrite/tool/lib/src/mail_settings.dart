import 'dart:math';

/// The `.env.local` variables that configure outgoing mail.
/// Never in git: `.env.local` is gitignored.
const List<String> mailEnvKeys = <String>[
  'MAIL_SMTP_HOST',
  'MAIL_SMTP_PORT',
  'MAIL_SMTP_USER',
  'MAIL_SMTP_PASSWORD',
  'MAIL_FROM',
  'MAIL_FROM_NAME',
  'MAIL_UNSUBSCRIBE_BASE_URL',
  // Only the live mail suite reads it: an address a person can check.
  'MAIL_TEST_RECIPIENT',
];

/// The submission port, used when `MAIL_SMTP_PORT` is unset.
const int defaultSmtpPort = 587;

/// The implicit-TLS port.
const int implicitTlsSmtpPort = 465;

/// The highest TCP port.
const int _maxPort = 65535;

/// The Function variable the unsubscribe links are signed with.
const String mailLinkSecretVariable = 'MAIL_LINK_SECRET';

/// Bytes of a generated link secret (hex encoded, twice as many characters).
const int _secretBytes = 32;

/// The values of one byte.
const int _byteValues = 256;

/// The radix and width of a byte written as hex.
const int _hex = 16;
const int _hexWidth = 2;

/// A random `MAIL_LINK_SECRET`: 32 bytes from `Random.secure()`, hex.
String generateMailLinkSecret() {
  final random = Random.secure();

  return List<String>.generate(
    _secretBytes,
    (_) =>
        random.nextInt(_byteValues).toRadixString(_hex).padLeft(_hexWidth, '0'),
  ).join();
}

/// One Function variable to create.
typedef MailVariable = ({String key, String value, bool secret});

/// The SMTP settings `bin/provision.dart` turns into the Appwrite Messaging
/// SMTP provider and the `api` Function's `MAIL_*` variables.
class MailSettings {
  /// Creates settings.
  const MailSettings({
    required this.host,
    required this.fromEmail,
    this.username,
    this.password,
    this.fromName,
    this.unsubscribeBaseUrl,
    this.port = defaultSmtpPort,
  });

  /// The SMTP host.
  final String host;

  /// The sender address.
  final String fromEmail;

  /// The SMTP user, if the server needs a login.
  final String? username;

  /// The SMTP password (a secret).
  final String? password;

  /// The sender's display name.
  final String? fromName;

  /// The URL the unsubscribe links point at (the `api` Function's execution
  /// domain plus `/unsubscribe`).
  final String? unsubscribeBaseUrl;

  /// The SMTP port.
  final int port;

  /// Whether the connection is implicit TLS (port 465), else STARTTLS.
  bool get implicitTls => port == implicitTlsSmtpPort;

  /// The `api` Function variables these settings become (the direct-SMTP
  /// transport reads them); the password is the only secret one.
  List<MailVariable> get functionVariables {
    final user = username;
    final pass = password;
    final name = fromName;
    final unsubscribe = unsubscribeBaseUrl;

    return <MailVariable>[
      (key: 'MAIL_SMTP_HOST', value: host, secret: false),
      (key: 'MAIL_SMTP_PORT', value: '$port', secret: false),
      (key: 'MAIL_FROM', value: fromEmail, secret: false),
      if (user != null) (key: 'MAIL_SMTP_USER', value: user, secret: false),
      if (pass != null) (key: 'MAIL_SMTP_PASSWORD', value: pass, secret: true),
      if (name != null) (key: 'MAIL_FROM_NAME', value: name, secret: false),
      if (unsubscribe != null)
        (key: 'MAIL_UNSUBSCRIBE_BASE_URL', value: unsubscribe, secret: false),
    ];
  }

  /// Reads the settings from [values] (the `MAIL_*` variables), or null when
  /// `MAIL_SMTP_HOST` or `MAIL_FROM` is missing: **mail is then not
  /// configured and provisioning skips it.** A set but unusable port throws
  /// [FormatException].
  static MailSettings? fromValues(Map<String, String> values) {
    final host = values['MAIL_SMTP_HOST'];
    final from = values['MAIL_FROM'];
    if (host == null || host.isEmpty || from == null || from.isEmpty) {
      return null;
    }
    final rawPort = values['MAIL_SMTP_PORT'];
    final port = rawPort == null || rawPort.isEmpty
        ? defaultSmtpPort
        : int.tryParse(rawPort);
    if (port == null || port < 1 || port > _maxPort) {
      throw FormatException('MAIL_SMTP_PORT must be a port, got "$rawPort".');
    }

    String? optional(String key) {
      final value = values[key];

      return value == null || value.isEmpty ? null : value;
    }

    return MailSettings(
      host: host,
      fromEmail: from,
      port: port,
      username: optional('MAIL_SMTP_USER'),
      password: optional('MAIL_SMTP_PASSWORD'),
      fromName: optional('MAIL_FROM_NAME'),
      unsubscribeBaseUrl: optional('MAIL_UNSUBSCRIBE_BASE_URL'),
    );
  }
}
