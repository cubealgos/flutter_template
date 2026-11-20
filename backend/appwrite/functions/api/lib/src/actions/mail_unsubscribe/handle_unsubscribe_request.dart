import 'dart:io';

import 'package:api/src/actions/mail_unsubscribe/unsubscribe_page_state.dart';
import 'package:api/src/actions/mail_unsubscribe/unsubscribe_reply.dart';
import 'package:api/src/function_response.dart';
import 'package:mailing/mailing.dart';

/// The body key naming the signed token.
const String unsubscribeTokenKey = 'token';

/// Whether this call records the unsubscribe (a POST) or only checks the
/// link (a GET): `true` records.
const String unsubscribeConfirmKey = 'confirm';

/// `"html"` answers with a page instead of JSON (the `/unsubscribe` URL in a
/// mail uses it).
const String unsubscribeFormatKey = 'format';

/// Verifies a signed unsubscribe link and, when confirmed, records the
/// unsubscribe.
///
/// **No sign-in.** The only authority is the token's HMAC signature: it names
/// one person and one subscription and expires, and *nothing* is read from
/// the body but the token and the two flags, so a caller cannot widen the
/// scope. A bad or expired token is a 400 and writes nothing; the response
/// says no more than that. Without [links] (no secret) the answer is a 503.
///
/// Recording is idempotent: unsubscribing twice answers 200 both times
/// (`alreadyUnsubscribed`). A call without `confirm: true` only checks the
/// link and answers `state: confirm`, so a mail scanner's GET unsubscribes no
/// one; RFC 8058 clients and the confirmation form POST (`confirm: true`).
Future<FunctionResponse> handleUnsubscribeRequest({
  required Map<String, dynamic> body,
  required UnsubscribeLinks? links,
  required Mailer mailer,
}) async {
  final reply = await _decide(body, links, mailer);

  return reply.toResponse(html: body[unsubscribeFormatKey] == 'html');
}

Future<UnsubscribeReply> _decide(
  Map<String, dynamic> body,
  UnsubscribeLinks? links,
  Mailer mailer,
) async {
  if (links == null) {
    return const UnsubscribeReply(
      status: HttpStatus.serviceUnavailable,
      state: UnsubscribePageState.notConfigured,
      errorCode: 'not_configured',
    );
  }
  final token = body[unsubscribeTokenKey];
  if (token is! String || token.isEmpty) {
    return const UnsubscribeReply(
      status: HttpStatus.badRequest,
      state: UnsubscribePageState.invalid,
      errorCode: 'invalid_link',
    );
  }
  final UnsubscribeClaim claim;
  try {
    claim = links.verify(token);
  } on InvalidUnsubscribeLinkError catch (e) {
    return UnsubscribeReply(
      status: HttpStatus.badRequest,
      state: UnsubscribePageState.invalid,
      errorCode: 'invalid_link',
      extra: <String, dynamic>{'reason': e.reason.name},
    );
  }
  if (body[unsubscribeConfirmKey] != true) {
    return UnsubscribeReply(
      status: HttpStatus.ok,
      state: UnsubscribePageState.confirm,
      locale: claim.locale,
      token: token,
      extra: <String, dynamic>{'subscription': claim.subscription},
    );
  }
  final recorded = await mailer.unsubscribe(claim.userId, claim.subscription);

  return UnsubscribeReply(
    status: HttpStatus.ok,
    state: UnsubscribePageState.unsubscribed,
    locale: claim.locale,
    extra: <String, dynamic>{
      'subscription': claim.subscription,
      'alreadyUnsubscribed': !recorded,
    },
  );
}
