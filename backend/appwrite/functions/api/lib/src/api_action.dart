import 'package:api/src/action_context.dart';
import 'package:api/src/function_response.dart';

/// One named operation of the `api` Function.
///
/// An action owns its own input validation, its own gateway and its own
/// tests; the router only authenticates, dispatches and maps errors. To add
/// one, see "Adding an action" in `backend/appwrite/README.md`.
abstract interface class ApiAction {
  /// The wire name, the `action` value callers send, snake_case.
  String get name;

  /// Whether a signed-in caller is required. The router refuses an
  /// unauthenticated call with 401 *before* [run] when this is true, so an
  /// action never has to re-check `ActionContext.callerUserId` for null.
  bool get requiresUser;

  /// The Appwrite API-key scopes this action needs. The Function's declared
  /// `FunctionSchema.scopes` must be exactly the union of every registered
  /// action's scopes (`test/scopes_test.dart` enforces it).
  Set<String> get scopes;

  /// The generic message returned (with HTTP 500) when [run] throws
  /// unexpectedly; the real error only goes to the Function log.
  String get failureMessage;

  /// Runs the action. Returns a [FunctionResponse] for every well-formed
  /// outcome, including refusals (400/401/...); only a genuine failure
  /// (e.g. an Appwrite error) may throw, which the router maps to 500.
  Future<FunctionResponse> run(ActionContext context);
}
