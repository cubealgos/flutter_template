import 'package:dart_appwrite/dart_appwrite.dart';

/// One inbound webhook request, as the router hands it to a hook.
///
/// Independent of the runtime's untyped `context` (see `lib/main.dart`), so a
/// hook is unit-testable by building one of these by hand.
class HookRequest {
  /// Creates a request.
  const HookRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.rawBody,
    required this.environment,
    required this.client,
    this.log,
  });

  /// The HTTP method.
  final String method;

  /// The request path, e.g. `/paddle` (no query string).
  final String path;

  /// The headers, names lowercased.
  final Map<String, String> headers;

  /// The **exact bytes** of the request body: what a signature covers. Never
  /// a re-serialisation of a parsed body.
  final List<int> rawBody;

  /// The Function's environment variables.
  final Map<String, String> environment;

  /// An Appwrite client with the execution's short-lived key (database scopes
  /// only; see `hooks` in `backend/appwrite/schema`).
  final Client client;

  /// A log sink (`context.error`). A hook never logs a body or a secret.
  final void Function(String message)? log;
}
