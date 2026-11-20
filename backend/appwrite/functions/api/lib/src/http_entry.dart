/// The path a mail's unsubscribe link has on the Function's own domain.
const String unsubscribePath = '/unsubscribe';

/// What the router receives for one HTTP request to the Function.
///
/// A call through the Appwrite Executions API carries a JSON body with an
/// `action`. A request to the Function's own domain at [unsubscribePath] (what
/// `List-Unsubscribe` points at) carries the token in the `t` query parameter
/// and no JSON, so it becomes a `mail_unsubscribe` call that asks for an HTML
/// page: a **POST** (RFC 8058 one-click, or the confirmation form) records
/// the unsubscribe, any other method only shows the confirmation page.
/// Everything else is [bodyJson] unchanged.
Object? routerBodyFor({
  required String method,
  required String path,
  required Map<String, dynamic>? query,
  required Object? bodyJson,
}) {
  if (path != unsubscribePath) return bodyJson;
  final token = query?['t'];

  return <String, dynamic>{
    'action': 'mail_unsubscribe',
    'token': token is String ? token : '',
    'confirm': method.toUpperCase() == 'POST',
    'format': 'html',
  };
}
