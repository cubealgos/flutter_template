import 'package:hooks/src/hook_request.dart';
import 'package:hooks/src/hook_response.dart';

/// One inbound webhook: a path, and the code that verifies and handles it.
abstract interface class WebhookHook {
  /// The path it answers, e.g. `/paddle`.
  String get path;

  /// Verifies and handles [request]. It must check the sender's signature
  /// before it reads anything else, and answer a non-2xx only when the sender
  /// should retry (or when the request is not genuine).
  Future<HookResponse> handle(HookRequest request);
}
