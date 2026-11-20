import 'package:api/src/actions/delete_account/deletion_service.dart';
import 'package:api/src/actions/delete_account/handle_delete_account_request.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:teams/teams.dart';
import 'package:test/test.dart';

import 'fakes/fake_account_deletion_gateway.dart';

const _schema = AppwriteSchema(
  databaseId: 'main',
  databaseName: 'Main',
  tables: <TableSchema>[],
  buckets: <BucketSchema>[],
  functions: <FunctionSchema>[],
);

void main() {
  test('refuses with 403 when there is no caller user ID', () async {
    final gateway = FakeAccountDeletionGateway();
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final response = await handleDeleteAccountRequest(
      callerUserId: null,
      service: service,
    );

    expect(response.statusCode, unauthenticatedStatusCode);
    expect(gateway.deletedUsers, isEmpty);
  });

  test('refuses with 403 when the caller user ID is empty', () async {
    final gateway = FakeAccountDeletionGateway();
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final response = await handleDeleteAccountRequest(
      callerUserId: '',
      service: service,
    );

    expect(response.statusCode, unauthenticatedStatusCode);
  });

  test('deletes the caller and returns 200 with the result JSON', () async {
    final gateway = FakeAccountDeletionGateway();
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final response = await handleDeleteAccountRequest(
      callerUserId: 'user-1',
      service: service,
    );

    expect(response.statusCode, okStatusCode);
    expect(response.body['userId'], 'user-1');
    expect(response.body['userDeleted'], isTrue);
    expect(gateway.deletedUsers, <String>['user-1']);
  });

  test('answers 409 owns_teams, with the team names, for an owner', () async {
    const ada = TeamActor(userId: 'ada', email: 'ada@example.com');
    final engine = TeamEngine(store: InMemoryTeamStore());
    await engine.createTeam(ada, 'Acme');
    final gateway = FakeAccountDeletionGateway();

    final response = await handleDeleteAccountRequest(
      callerUserId: 'ada',
      service: DeletionService(
        gateway: gateway,
        schema: _schema,
        teams: engine,
      ),
    );

    expect(response.statusCode, ownsTeamsStatusCode);
    final error = response.body['error'] as Map<String, dynamic>;
    expect(error['code'], ownsTeamsErrorCode);
    expect(error['teams'], <String>['Acme']);
    expect(error['message'], allOf(contains('"Acme"'), contains('Transfer')));
    expect(gateway.deletedUsers, isEmpty);
  });
}
