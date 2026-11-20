import 'package:api/src/action_context.dart';
import 'package:api/src/actions/delete_account/appwrite_account_deletion_gateway.dart';
import 'package:api/src/actions/delete_account/deletion_service.dart';
import 'package:api/src/actions/delete_account/handle_delete_account_request.dart';
import 'package:api/src/actions/team_admin/appwrite_team_store.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:teams/teams.dart';

/// The `delete_account` action: deletes the calling user's own rows and
/// files (per `backend/appwrite/schema`'s ownership declarations), then the
/// account itself. **Refuses while the caller owns a team**,
/// naming the teams: the exactly-one-owner invariant would break. Takes no
/// body fields - the account is always the caller's, from the
/// `x-appwrite-user-id` header.
class DeleteAccountAction implements ApiAction {
  /// Creates the action.
  const DeleteAccountAction();

  @override
  String get name => 'delete_account';

  @override
  bool get requiresUser => true;

  /// Deletes the caller's own rows, files, and finally their account.
  @override
  Set<String> get scopes => const <String>{
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
    'files.read',
    'files.write',
    'users.read',
    'users.write',
    // Which teams the caller owns (`TeamEngine.ownedTeams`).
    'teams.read',
  };

  @override
  String get failureMessage => 'Account deletion failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final gateway = AppwriteAccountDeletionGateway(
      client: context.client,
      databaseId: templateSchema.databaseId,
    );

    return handleDeleteAccountRequest(
      callerUserId: context.callerUserId,
      service: DeletionService(
        gateway: gateway,
        schema: templateSchema,
        teams: TeamEngine(
          store: AppwriteTeamStore(
            client: context.client,
            databaseId: templateSchema.databaseId,
          ),
        ),
      ),
    );
  }
}
