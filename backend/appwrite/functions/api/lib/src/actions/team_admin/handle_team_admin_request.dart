import 'package:api/src/actions/team_admin/bad_request_error.dart';
import 'package:api/src/actions/team_admin/team_actions.dart';
import 'package:api/src/function_response.dart';
import 'package:teams/teams.dart';

/// The HTTP status a malformed request is refused with.
const int badRequestStatusCode = 400;

/// The HTTP status a successful call responds with.
const int okStatusCode = 200;

/// Runs one team operation for the caller and builds the Function's
/// response.
///
/// The body is `{"op": ..., ...arguments}` (the router has already consumed
/// its own `action`; see `TeamWire` and
/// `runTeamAction`); the action names are exactly `TeamService`'s method
/// names. [callerUserId] is the execution's `x-appwrite-user-id` header,
/// which Appwrite sets and a client can't forge; [resolveActor] turns it
/// into a `TeamActor` (it also refuses a caller whose email is not
/// verified, since invitations are matched by email). Every `TeamError`
/// becomes its wire status and body; anything else propagates to
/// `lib/main.dart`, which answers 500.
///
/// Kept independent of the Appwrite runtime's untyped `context` (see
/// `lib/main.dart`) so it is directly unit-testable.
Future<FunctionResponse> handleTeamAdminRequest({
  required String? callerUserId,
  required Map<String, dynamic>? body,
  required TeamEngine engine,
  required Future<TeamActor> Function(String userId) resolveActor,
}) async {
  if (callerUserId == null || callerUserId.isEmpty) {
    return _failure(
      const TeamUnauthenticatedError('Call this function as a signed-in user.'),
    );
  }
  final action = body?['op'];
  if (body == null || action is! String) {
    return _badRequest('The body must carry the operation in "op".');
  }
  try {
    final actor = await resolveActor(callerUserId);
    final result = await runTeamAction(action, engine, actor, body);

    return FunctionResponse(
      body: <String, dynamic>{'result': result},
      statusCode: okStatusCode,
    );
  } on BadRequestError catch (e) {
    return _badRequest(e.message);
  } on TeamError catch (e) {
    return _failure(e);
  }
}

FunctionResponse _failure(TeamError error) => FunctionResponse(
  body: TeamWire.encodeError(error),
  statusCode: TeamWire.statusFor(error),
);

FunctionResponse _badRequest(String message) => FunctionResponse(
  body: <String, dynamic>{
    'error': <String, dynamic>{'code': 'bad_request', 'message': message},
  },
  statusCode: badRequestStatusCode,
);
