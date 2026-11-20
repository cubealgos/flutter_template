import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as models;

/// What `MessagingMailTransport` needs of Appwrite Messaging, behind an
/// interface so the transport is unit-testable without a live project.
abstract interface class MessagingGateway {
  /// Creates and sends [email] to the user's own email target through the
  /// project's enabled email provider (the SMTP provider `appwrite_tool`
  /// creates). Messaging has **no parameter for custom headers**.
  Future<MessagingMessage> createEmail(MessagingEmail email);

  /// The message with [messageId].
  Future<MessagingMessage> getMessage(String messageId);
}

/// One email for [MessagingGateway.createEmail].
class MessagingEmail {
  /// Creates the email.
  const MessagingEmail({
    required this.messageId,
    required this.userId,
    required this.subject,
    required this.content,
    required this.html,
  });

  /// The message ID Appwrite stores it under (unique: a second create with
  /// it is a 409).
  final String messageId;

  /// The recipient's user ID.
  final String userId;

  /// The subject line.
  final String subject;

  /// The body.
  final String content;

  /// Whether [content] is HTML.
  final bool html;
}

/// What Messaging reports about a message: its status, how many targets it
/// reached and its errors. Messaging reports no bounce.
class MessagingMessage {
  /// Creates the report.
  const MessagingMessage({
    required this.id,
    required this.status,
    required this.deliveredTotal,
    this.errors = const <String>[],
  });

  /// The message ID.
  final String id;

  /// Appwrite's `MessageStatus` name: draft, processing, scheduled, sent,
  /// failed.
  final String status;

  /// Recipients it was delivered to.
  final int deliveredTotal;

  /// Delivery errors, if any.
  final List<String> errors;
}

/// The [MessagingGateway] over `dart_appwrite`'s `Messaging` service (needs the
/// `messages.read`/`messages.write` scopes).
class AppwriteMessagingGateway implements MessagingGateway {
  /// Creates the gateway over [client].
  AppwriteMessagingGateway(Client client) : _messaging = Messaging(client);

  final Messaging _messaging;

  @override
  Future<MessagingMessage> createEmail(MessagingEmail email) async => _of(
    await _messaging.createEmail(
      messageId: email.messageId,
      subject: email.subject,
      content: email.content,
      users: <String>[email.userId],
      html: email.html,
    ),
  );

  @override
  Future<MessagingMessage> getMessage(String messageId) async =>
      _of(await _messaging.getMessage(messageId: messageId));

  static MessagingMessage _of(models.Message message) => MessagingMessage(
    id: message.$id,
    status: message.status.value,
    deliveredTotal: message.deliveredTotal,
    errors: message.deliveryErrors ?? const <String>[],
  );
}
