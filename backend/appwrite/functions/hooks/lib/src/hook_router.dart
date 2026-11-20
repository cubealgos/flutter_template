import 'package:hooks/src/hook_request.dart';
import 'package:hooks/src/hook_response.dart';
import 'package:hooks/src/webhook_hook.dart';

/// 404: no hook answers the path.
const int hookNotFoundStatus = 404;

/// 405: webhooks are POSTs.
const int hookMethodNotAllowedStatus = 405;

/// 500: the hook threw; the sender should retry.
const int hookFailedStatus = 500;

/// Routes a request to the [WebhookHook] of its path. Everything about a hook
/// (its signature, its secret, its body) is the hook's own.
class HookRouter {
  /// Creates a router over [hooks]. Throws [ArgumentError] on a duplicate
  /// path.
  HookRouter({required Iterable<WebhookHook> hooks, this.log})
    : _byPath = _index(hooks);

  /// A log sink for failures.
  final void Function(String message)? log;

  final Map<String, WebhookHook> _byPath;

  static Map<String, WebhookHook> _index(Iterable<WebhookHook> hooks) {
    final byPath = <String, WebhookHook>{};
    for (final hook in hooks) {
      if (byPath.containsKey(hook.path)) {
        throw ArgumentError('Duplicate hook path "${hook.path}".');
      }
      byPath[hook.path] = hook;
    }

    return byPath;
  }

  /// Handles [request]. A throwing hook is a 500 with a generic body and the
  /// cause in the log only, so the sender retries and nothing leaks.
  Future<HookResponse> handle(HookRequest request) async {
    final hook = _byPath[_normalise(request.path)];
    if (hook == null) {
      return const HookResponse(
        statusCode: hookNotFoundStatus,
        body: <String, dynamic>{'error': 'not_found'},
      );
    }
    if (request.method.toUpperCase() != 'POST') {
      return const HookResponse(
        statusCode: hookMethodNotAllowedStatus,
        body: <String, dynamic>{'error': 'method_not_allowed'},
      );
    }
    try {
      return await hook.handle(request);
    } on Exception catch (e) {
      log?.call('hook ${hook.path} failed: $e');

      return const HookResponse(
        statusCode: hookFailedStatus,
        body: <String, dynamic>{'error': 'failed'},
      );
    }
  }

  static String _normalise(String path) {
    final bare = path.split('?').first;

    return bare.length > 1 && bare.endsWith('/')
        ? bare.substring(0, bare.length - 1)
        : bare;
  }
}
