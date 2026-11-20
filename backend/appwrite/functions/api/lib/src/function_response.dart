/// A Function's response, independent of the Appwrite Dart runtime's own
/// `context.res` type — the runtime passes an untyped `context` (see
/// `lib/main.dart`), so there is no importable Dart type for it to unit
/// test against. `main.dart` maps this to a real `context.res.json` call, or
/// `context.res.text` when [html] is set.
class FunctionResponse {
  /// Creates a JSON response, or an HTML page when [html] is given.
  const FunctionResponse({
    required this.body,
    required this.statusCode,
    this.html,
    this.headers = const <String, String>{},
  });

  /// The JSON-serializable response body.
  final Map<String, dynamic> body;

  /// The HTTP status code.
  final int statusCode;

  /// An HTML page to answer with instead of [body] (the unsubscribe
  /// confirmation), or null for JSON.
  final String? html;

  /// Extra response headers (`Cache-Control`, `Referrer-Policy`).
  final Map<String, String> headers;
}
