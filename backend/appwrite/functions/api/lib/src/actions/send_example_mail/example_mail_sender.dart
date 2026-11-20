import 'dart:io';

import 'package:api/src/function_response.dart';
import 'package:api/src/mail/mail_not_configured_exception.dart';
import 'package:api/src/rate_limit/rate_limiter.dart';
import 'package:mailing/mailing.dart';

/// How many example mails a user may ask for per [exampleMailWindow].
const int exampleMailLimit = 5;

/// The window of [exampleMailLimit].
const Duration exampleMailWindow = Duration(hours: 1);

/// The longest `requestId` accepted.
const int _maxRequestIdLength = 64;

/// Looks up the signed-in user's verified address, or null.
typedef RecipientLookup = Future<MailRecipient?> Function(String userId);

/// Sends the template's one example mail (`example_digest`) to the caller
/// — the end-to-end path a clone copies for its own mail: look the
/// recipient up by the router's `x-appwrite-user-id` (never the body), limit
/// the rate, render the localised template, send through the `Mailer`.
class ExampleMailSender {
  /// Creates the sender over [mailer], [lookup] and [limiter] (null when the
  /// rate limiter is not configured, which refuses every call).
  const ExampleMailSender({
    required this.mailer,
    required this.lookup,
    required this.limiter,
  });

  /// The mailer.
  final Mailer mailer;

  /// Finds the caller's address.
  final RecipientLookup lookup;

  /// Limits calls per user, or null.
  final RateLimiter? limiter;

  /// Handles one call by [callerUserId].
  ///
  /// The body is `{"requestId": "...", "locale": "de"}`: `requestId` is
  /// client-chosen (1 to 64 of `A-Z a-z 0-9 _ -`) and the idempotency key is
  /// `example_digest:<user>:<requestId>`, so a retried request mails once.
  /// Answers 200 with the delivery `status`, `replayed` and `detail`; 400 for
  /// a bad body; 429 over the limit; 503 when the mailer is not configured or
  /// the mail was not sent (a retry may send).
  Future<FunctionResponse> handle(
    String callerUserId,
    Map<String, dynamic> body,
  ) async {
    final requestId = body['requestId'];
    if (requestId is! String || !_validRequestId(requestId)) {
      return _error(HttpStatus.badRequest, 'invalid_request', 'Bad requestId.');
    }
    final refusal = await _limit(callerUserId);
    if (refusal != null) return refusal;
    final recipient = await lookup(callerUserId);
    if (recipient == null) {
      return _error(
        HttpStatus.forbidden,
        'no_verified_email',
        'This account has no verified email address.',
      );
    }

    return await _send(
      MailMessage(
        idempotencyKey: 'example_digest:$callerUserId:$requestId',
        recipient: recipient,
        templateId: 'example_digest',
        locale: MailLocale.parse(body['locale'] as String?),
        data: const <String, String>{'name': 'there', 'count': '3'},
      ),
    );
  }

  static bool _validRequestId(String id) =>
      id.isNotEmpty &&
      id.length <= _maxRequestIdLength &&
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);

  Future<FunctionResponse?> _limit(String callerUserId) async {
    final limiter = this.limiter;
    if (limiter == null) {
      return _error(
        HttpStatus.serviceUnavailable,
        'not_configured',
        'Set RATE_LIMIT_SECRET on the Function to enable this action.',
      );
    }
    final decision = await limiter.check(
      scope: 'send_example_mail',
      key: callerUserId,
      limit: exampleMailLimit,
      window: exampleMailWindow,
    );

    return decision.allowed
        ? null
        : _error(
            HttpStatus.tooManyRequests,
            'rate_limited',
            'Try again in ${decision.retryAfter.inMinutes + 1} minutes.',
          );
  }

  Future<FunctionResponse> _send(MailMessage message) async {
    try {
      final result = await mailer.send(message);

      return FunctionResponse(
        statusCode: HttpStatus.ok,
        body: <String, dynamic>{
          'status': result.status.name,
          'replayed': result.replayed,
          if (result.detail != null) 'detail': result.detail,
        },
      );
    } on MailNotSentException catch (e) {
      return _error(HttpStatus.serviceUnavailable, 'not_sent', e.message);
    } on MailNotConfiguredException catch (e) {
      return _error(HttpStatus.serviceUnavailable, 'not_configured', e.message);
    } on MailInvalidError catch (e) {
      return _error(HttpStatus.badRequest, 'invalid_request', e.message);
    }
  }

  static FunctionResponse _error(int status, String code, String message) =>
      FunctionResponse(
        statusCode: status,
        body: <String, dynamic>{
          'error': <String, dynamic>{'code': code, 'message': message},
        },
      );
}
