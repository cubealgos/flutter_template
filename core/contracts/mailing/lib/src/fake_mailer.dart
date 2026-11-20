import 'package:mailing/src/example_digest_template.dart';
import 'package:mailing/src/in_memory_mail_store.dart';
import 'package:mailing/src/mail_catalog.dart';
import 'package:mailing/src/mail_delivery_result.dart';
import 'package:mailing/src/mail_message.dart';
import 'package:mailing/src/mailer.dart';
import 'package:mailing/src/mailer_engine.dart';
import 'package:mailing/src/recording_mail_transport.dart';
import 'package:mailing/src/rendered_mail.dart';
import 'package:mailing/src/unsubscribe_links.dart';

/// An in-memory [Mailer] that records sent mail, for tests: the real
/// `MailerEngine` over an `InMemoryMailStore` and a `RecordingMailTransport`,
/// so a test sees the same idempotency, suppression and header rules
/// production runs.
class FakeMailer implements Mailer {
  /// Creates a fake. [catalog] defaults to the example catalog; the links
  /// default to a fixed test secret and `https://example.test/unsubscribe`.
  FakeMailer({
    MailCatalog? catalog,
    UnsubscribeLinks? links,
    DateTime Function()? clock,
  }) : this._(
         InMemoryMailStore(),
         RecordingMailTransport(),
         catalog ?? defaultMailCatalog(),
         links ??
             UnsubscribeLinks(
               secret: 'fake-mailer-secret',
               endpoint: Uri.parse('https://example.test/unsubscribe'),
               clock: clock,
             ),
         clock,
       );

  FakeMailer._(
    this.store,
    this.transport,
    MailCatalog catalog,
    UnsubscribeLinks links,
    DateTime Function()? clock,
  ) : _engine = MailerEngine(
        store: store,
        transport: transport,
        catalog: catalog,
        links: links,
        clock: clock,
      );

  /// The delivery records and suppressions.
  final InMemoryMailStore store;

  /// The recorder behind the fake.
  final RecordingMailTransport transport;

  final MailerEngine _engine;

  /// Every mail that reached the transport, in order.
  List<RenderedMail> get sent => transport.sent;

  @override
  Future<MailDeliveryResult> send(MailMessage message) => _engine.send(message);

  @override
  Future<MailDeliveryResult?> status(String idempotencyKey) =>
      _engine.status(idempotencyKey);

  @override
  Future<MailDeliveryResult?> recordBounce(
    String idempotencyKey, {
    String? reason,
  }) => _engine.recordBounce(idempotencyKey, reason: reason);

  @override
  Future<bool> unsubscribe(String userId, String subscription) =>
      _engine.unsubscribe(userId, subscription);
}
