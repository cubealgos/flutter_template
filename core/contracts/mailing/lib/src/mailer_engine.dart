import 'dart:convert';

import 'package:mailing/src/mail_catalog.dart';
import 'package:mailing/src/mail_delivery_record.dart';
import 'package:mailing/src/mail_delivery_result.dart';
import 'package:mailing/src/mail_delivery_status.dart';
import 'package:mailing/src/mail_invalid_error.dart';
import 'package:mailing/src/mail_message.dart';
import 'package:mailing/src/mail_not_sent_exception.dart';
import 'package:mailing/src/mail_store.dart';
import 'package:mailing/src/mail_template.dart';
import 'package:mailing/src/mail_transport.dart';
import 'package:mailing/src/mail_transport_result.dart';
import 'package:mailing/src/mailer.dart';
import 'package:mailing/src/rendered_mail.dart';
import 'package:mailing/src/unsubscribe_links.dart';

/// The longest idempotency key accepted.
const int maxIdempotencyKeyLength = 200;

/// The header naming the unsubscribe URL (RFC 2369).
const String listUnsubscribeHeader = 'List-Unsubscribe';

/// The header announcing one-click POST unsubscribe (RFC 8058).
const String listUnsubscribePostHeader = 'List-Unsubscribe-Post';

/// The value RFC 8058 requires for [listUnsubscribePostHeader].
const String listUnsubscribePostValue = 'List-Unsubscribe=One-Click';

/// The one implementation of [Mailer]'s rules, over a [MailStore] and a
/// [MailTransport]: `FakeMailer` runs it in memory, `api` on Appwrite.
///
/// **Idempotency.** [send] claims the idempotency key by inserting a delivery
/// record (unique on the key) *before* it hands the mail to the transport, so
/// of any number of concurrent or retried sends exactly one reaches the
/// transport. That is **at most once**: a crash between the claim and the
/// outcome leaves a `pending` record and a retry does not send again (use a new
/// key to force it). Only a transport that says nothing left
/// (`MailNotSentException`) releases the claim, so a retry may send.
///
/// **No tracking.** The engine adds no pixel and rewrites no link; the only
/// link it ever puts in a mail is the unsubscribe one.
class MailerEngine implements Mailer {
  /// Creates an engine. [links] is required to send a non-transactional mail.
  MailerEngine({
    required this.store,
    required this.transport,
    required this.catalog,
    this.links,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The persistence.
  final MailStore store;

  /// The provider.
  final MailTransport transport;

  /// The templates.
  final MailCatalog catalog;

  /// Makes the unsubscribe links, or null when none are configured.
  final UnsubscribeLinks? links;

  final DateTime Function() _clock;

  @override
  Future<MailDeliveryResult> send(MailMessage message) async {
    final template = _templateFor(message);
    final subscription = template.subscription;
    if (subscription != null &&
        await store.isSuppressed(message.recipient.userId, subscription)) {
      return MailDeliveryResult(
        idempotencyKey: message.idempotencyKey,
        status: MailDeliveryStatus.suppressed,
        detail: 'The recipient unsubscribed from "$subscription" or bounced.',
      );
    }
    final rendered = _render(message, template);
    final record = MailDeliveryRecord(
      idempotencyKey: message.idempotencyKey,
      userId: message.recipient.userId,
      templateId: template.id,
      locale: message.locale,
      status: MailDeliveryStatus.pending,
      createdAt: _clock().toUtc(),
    );
    if (!await store.claim(record)) {
      return await _replay(message.idempotencyKey);
    }

    return await _dispatch(record, rendered);
  }

  Future<MailDeliveryResult> _replay(String key) async {
    final existing = await store.find(key);
    if (existing == null) {
      // The claim was released between our insert and our read: a send that
      // never left. Say so rather than loop; the caller retries.
      return MailDeliveryResult(
        idempotencyKey: key,
        status: MailDeliveryStatus.pending,
        replayed: true,
        detail: 'A concurrent send with this key was released; retry.',
      );
    }

    return existing.toResult(replayed: true);
  }

  Future<MailDeliveryResult> _dispatch(
    MailDeliveryRecord record,
    RenderedMail rendered,
  ) async {
    final MailTransportResult outcome;
    try {
      outcome = await transport.send(rendered);
    } on MailNotSentException {
      await store.release(record.idempotencyKey);
      rethrow;
    } on Object catch (e) {
      await store.update(
        record.withOutcome(
          status: MailDeliveryStatus.failed,
          detail: 'Outcome unknown, not retried: $e',
        ),
      );
      rethrow;
    }
    final done = record.withOutcome(
      status: outcome.status,
      providerMessageId: outcome.providerMessageId,
      detail: outcome.detail,
    );
    await store.update(done);

    return done.toResult();
  }

  @override
  Future<MailDeliveryResult?> status(String idempotencyKey) async {
    final record = await store.find(idempotencyKey);
    if (record == null) return null;
    final providerId = record.providerMessageId;
    if (providerId == null || record.status != MailDeliveryStatus.accepted) {
      return record.toResult();
    }
    final fresh = await transport.refresh(providerId);
    if (fresh == null) return record.toResult();
    final updated = record.withOutcome(
      status: fresh.status,
      providerMessageId: fresh.providerMessageId,
      detail: fresh.detail,
    );
    await store.update(updated);

    return updated.toResult();
  }

  @override
  Future<MailDeliveryResult?> recordBounce(
    String idempotencyKey, {
    String? reason,
  }) async {
    final record = await store.find(idempotencyKey);
    if (record == null) return null;
    final updated = record.withOutcome(
      status: MailDeliveryStatus.bounced,
      detail: reason ?? 'bounced',
    );
    await store.update(updated);
    await store.suppress(record.userId, allSubscriptions, 'bounced');

    return updated.toResult();
  }

  @override
  Future<bool> unsubscribe(String userId, String subscription) =>
      store.suppress(userId, subscription, 'unsubscribed');

  MailTemplate _templateFor(MailMessage message) {
    final key = message.idempotencyKey;
    if (key.isEmpty || key.length > maxIdempotencyKeyLength) {
      throw const MailInvalidError(
        'The idempotency key must be 1 to $maxIdempotencyKeyLength '
        'characters.',
      );
    }
    final template = catalog.templateFor(message.templateId);
    if (template == null) {
      throw MailInvalidError('Unknown mail template "${message.templateId}".');
    }
    for (final entry in message.headers.entries) {
      _checkHeader(entry.key, entry.value);
    }

    return template;
  }

  static void _checkHeader(String name, String value) {
    final lower = name.toLowerCase();
    if (lower == listUnsubscribeHeader.toLowerCase() ||
        lower == listUnsubscribePostHeader.toLowerCase()) {
      throw MailInvalidError('"$name" is set by the mailer, not the caller.');
    }
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9-]*$').hasMatch(name) ||
        value.contains('\r') ||
        value.contains('\n')) {
      throw MailInvalidError('Header "$name" is malformed.');
    }
  }

  RenderedMail _render(MailMessage message, MailTemplate template) {
    final strings = template.stringsFor(message.locale);
    final data = message.data;
    final subject = MailCatalog.fill(
      strings.subject,
      data,
    ).replaceAll(RegExp(r'[\r\n]+'), ' ');
    var text = MailCatalog.fill(strings.text, data);
    final htmlSource = strings.html;
    var html = htmlSource == null
        ? null
        : MailCatalog.fill(htmlSource, data, escape: _escapeHtml);
    final headers = <String, String>{...message.headers};

    final subscription = template.subscription;
    if (subscription != null) {
      final url = _unsubscribeUrl(message, subscription);
      final footer = unsubscribeFooterFor(message.locale);
      text = '$text\n\n-- \n${footer.text.replaceAll('{url}', url)}';
      if (html != null) {
        html = '$html${footer.html.replaceAll('{url}', _escapeHtml(url))}';
      }
      headers[listUnsubscribeHeader] = '<$url>';
      headers[listUnsubscribePostHeader] = listUnsubscribePostValue;
    }

    return RenderedMail(
      idempotencyKey: message.idempotencyKey,
      recipient: message.recipient,
      templateId: template.id,
      locale: message.locale,
      subject: subject,
      text: text,
      html: html,
      headers: headers,
      subscription: subscription,
    );
  }

  String _unsubscribeUrl(MailMessage message, String subscription) {
    final signer = links;
    if (signer == null) {
      throw const MailNotSentException(
        'A non-transactional mail needs unsubscribe links, and none are '
        'configured (set the unsubscribe secret and base URL).',
      );
    }

    return signer
        .linkFor(
          userId: message.recipient.userId,
          subscription: subscription,
          locale: message.locale,
        )
        .toString();
  }

  static String _escapeHtml(String value) =>
      const HtmlEscape(HtmlEscapeMode.attribute).convert(value);
}
