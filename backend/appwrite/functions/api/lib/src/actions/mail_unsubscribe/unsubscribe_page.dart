import 'dart:convert';

import 'package:api/src/actions/mail_unsubscribe/unsubscribe_page_state.dart';
import 'package:mailing/mailing.dart';

typedef _Copy = ({String title, String body, String button});

_Copy _copyOf(MailLocale locale, UnsubscribePageState state) =>
    switch (locale) {
      MailLocale.en => _copyEn(state),
      MailLocale.de => _copyDe(state),
    };

_Copy _copyEn(UnsubscribePageState state) => switch (state) {
  UnsubscribePageState.confirm => (
    title: 'Unsubscribe',
    body: 'Stop receiving these emails?',
    button: 'Unsubscribe',
  ),
  UnsubscribePageState.unsubscribed => (
    title: 'You are unsubscribed',
    body: 'You will not receive these emails any more.',
    button: '',
  ),
  UnsubscribePageState.invalid => (
    title: 'Link not valid',
    body:
        'This unsubscribe link is invalid or has expired. Use the '
        'link in a more recent email.',
    button: '',
  ),
  UnsubscribePageState.notConfigured => (
    title: 'Unavailable',
    body: 'Unsubscribing is not available right now. Try again later.',
    button: '',
  ),
};

_Copy _copyDe(UnsubscribePageState state) => switch (state) {
  UnsubscribePageState.confirm => (
    title: 'Abbestellen',
    body: 'Diese E-Mails nicht mehr erhalten?',
    button: 'Abbestellen',
  ),
  UnsubscribePageState.unsubscribed => (
    title: 'Abbestellt',
    body: 'Sie erhalten diese E-Mails nicht mehr.',
    button: '',
  ),
  UnsubscribePageState.invalid => (
    title: 'Link ungültig',
    body:
        'Dieser Abmeldelink ist ungültig oder abgelaufen. Nutzen Sie '
        'den Link in einer neueren E-Mail.',
    button: '',
  ),
  UnsubscribePageState.notConfigured => (
    title: 'Nicht verfügbar',
    body:
        'Das Abbestellen ist gerade nicht möglich. Bitte versuchen '
        'Sie es später erneut.',
    button: '',
  ),
};

/// The headers every unsubscribe page carries: the token is in the URL, so
/// nothing may be cached or leak through a referrer, and the page runs no
/// script.
const Map<String, String> unsubscribePageHeaders = <String, String>{
  'Cache-Control': 'no-store',
  'Referrer-Policy': 'no-referrer',
  'Content-Security-Policy':
      "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; "
      "frame-ancestors 'none'",
};

const HtmlEscape _escape = HtmlEscape(HtmlEscapeMode.attribute);

/// The tiny HTML page for [state] in [locale]. For
/// [UnsubscribePageState.confirm] it holds a form that POSTs to the same
/// URL with [token] in the query (RFC 8058's one-click request, from a
/// browser).
String unsubscribePageHtml(
  UnsubscribePageState state,
  MailLocale locale, {
  String? token,
}) {
  final copy = _copyOf(locale, state);
  final title = _escape.convert(copy.title);
  final form = state == UnsubscribePageState.confirm && token != null
      ? '''
<form method="post" action="?t=${_escape.convert(token)}">
<input type="hidden" name="List-Unsubscribe" value="One-Click">
<button type="submit">${_escape.convert(copy.button)}</button>
</form>'''
      : '';

  return '''
<!doctype html>
<html lang="${locale.tag}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>$title</title>
<style>body{font:16px/1.5 system-ui,sans-serif;max-width:32rem;margin:4rem auto;padding:0 1rem}button{font:inherit;padding:.5rem 1rem}</style>
</head>
<body>
<h1>$title</h1>
<p>${_escape.convert(copy.body)}</p>
$form
</body>
</html>
''';
}
