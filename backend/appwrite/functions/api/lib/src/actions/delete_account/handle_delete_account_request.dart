import 'package:api/src/actions/delete_account/account_owns_teams_exception.dart';
import 'package:api/src/actions/delete_account/deletion_service.dart';
import 'package:api/src/function_response.dart';

/// The HTTP status code a request with no caller identity gets refused
/// with.
const int unauthenticatedStatusCode = 403;

/// The HTTP status code a successful deletion result is returned with, no
/// matter whether the deletion result's `userDeleted` field itself came
/// back true or false — the request was handled correctly either way; the
/// result body is what reports partial failure.
const int okStatusCode = 200;

/// The HTTP status a refusal because the caller still owns a team is
/// answered with (a conflict with the team rules; the `AuthOwnsTeamsError`
/// the app shows).
const int ownsTeamsStatusCode = 409;

/// The wire `error.code` of that refusal.
const String ownsTeamsErrorCode = 'owns_teams';

/// Builds the Function's response: refuses with
/// [unauthenticatedStatusCode] if [callerUserId] is unset, refuses with
/// [ownsTeamsStatusCode] (body `{"error": {"code": "owns_teams", "message":
/// ..., "teams": the names}}`) if the caller owns a team, otherwise runs
/// [service] and returns its result as JSON.
///
/// Kept independent of the Appwrite runtime's own untyped `context` (see
/// `lib/main.dart`) so it is directly unit-testable.
Future<FunctionResponse> handleDeleteAccountRequest({
  required String? callerUserId,
  required DeletionService service,
}) async {
  if (callerUserId == null || callerUserId.isEmpty) {
    return const FunctionResponse(
      body: <String, dynamic>{
        'error': 'This function must be called by an authenticated user.',
      },
      statusCode: unauthenticatedStatusCode,
    );
  }

  try {
    final result = await service.deleteAccount(callerUserId);

    return FunctionResponse(body: result.toJson(), statusCode: okStatusCode);
  } on AccountOwnsTeamsException catch (e) {
    return FunctionResponse(
      body: <String, dynamic>{
        'error': <String, dynamic>{
          'code': ownsTeamsErrorCode,
          'message': e.message,
          'teams': e.teamNames,
        },
      },
      statusCode: ownsTeamsStatusCode,
    );
  }
}
