import 'package:api/src/action_context.dart';
import 'package:api/src/actions/team_admin/appwrite_team_store.dart';
import 'package:api/src/actions/team_admin/handle_team_admin_request.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:teams/teams.dart';

/// The `team_admin` action: every team operation (create, invite, accept,
/// revoke, role change, removal, leave, ownership transfer, history) for the
/// signed-in caller, by running `package:teams`'s `TeamEngine` on Appwrite
/// Teams and the server-only tables. The body carries the operation in `op`
/// (the names are `TeamService`'s method names) plus its arguments. See
/// `AppwriteTeamService` for why this is a Function and not the Teams SDK.
///
/// The caller is only ever the router's `x-appwrite-user-id`, and one whose
/// email is not verified is refused: invitations match on email.
class TeamAdminAction implements ApiAction {
  /// Creates the action.
  const TeamAdminAction();

  @override
  String get name => 'team_admin';

  @override
  bool get requiresUser => true;

  /// `users.read` for the caller's verified email, `teams.*` for
  /// memberships, tables/documents for invitations and the history.
  @override
  Set<String> get scopes => const <String>{
    'users.read',
    'teams.read',
    'teams.write',
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
  };

  @override
  String get failureMessage => 'Team operation failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final users = Users(context.client);

    return handleTeamAdminRequest(
      callerUserId: context.callerUserId,
      body: context.body,
      engine: TeamEngine(
        store: AppwriteTeamStore(
          client: context.client,
          databaseId: templateSchema.databaseId,
        ),
        newId: ID.unique,
      ),
      resolveActor: (userId) => _verifiedActor(users, userId),
    );
  }

  /// The caller as a `TeamActor`: an account whose email is unverified can't
  /// act on a team at all.
  Future<TeamActor> _verifiedActor(Users users, String userId) async {
    final user = await users.get(userId: userId);
    if (!user.emailVerification || user.email.isEmpty) {
      throw const TeamPermissionError(
        'A verified email address is required to use teams.',
      );
    }

    return TeamActor(userId: userId, email: user.email);
  }
}
