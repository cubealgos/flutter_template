import 'package:api/src/api_action.dart' show ApiAction;
import 'package:dart_appwrite/dart_appwrite.dart';

/// What the router hands an [ApiAction] when it runs.
///
/// Deliberately small and free of the Appwrite runtime's untyped `context`
/// (see `lib/main.dart`), so an action is unit-testable by building one of
/// these by hand.
class ActionContext {
  /// Creates a context.
  const ActionContext({
    required this.callerUserId,
    required this.body,
    required this.environment,
    required this.client,
    this.callerAddress,
    this.log,
  });

  /// The signed-in caller's user ID, taken from the execution's
  /// `x-appwrite-user-id` header by the router - **never** from [body]. Null
  /// when the call carries no session; always non-null for an action with
  /// `ApiAction.requiresUser`.
  final String? callerUserId;

  /// The request body, parsed JSON object, with the router's own `action`
  /// key removed. Each action validates the fields it reads.
  final Map<String, dynamic> body;

  /// The Function's environment variables (`Platform.environment` in
  /// production).
  final Map<String, String> environment;

  /// An Appwrite client authenticated with this execution's short-lived
  /// key, whose scopes are the union of every action's `ApiAction.scopes`.
  final Client client;

  /// The caller's network address as the platform reports it (the
  /// execution's `x-forwarded-for` header), or null when there is none (a
  /// cron tick, a server-side call). Unauthenticated actions key their
  /// `RateLimiter` on it; treat it as a hint, never as an identity (see
  /// "Rate limiting" in `backend/appwrite/README.md`).
  final String? callerAddress;

  /// A sink for run logs (`context.error` in production, the only log
  /// channel the runtime exposes), or null. Scheduled jobs log each run here.
  final void Function(String message)? log;
}
