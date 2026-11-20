import 'package:api/src/actions/delete_account/account_owns_teams_exception.dart';
import 'package:api/src/actions/delete_account/deletion_service.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:teams/teams.dart';
import 'package:test/test.dart';

import 'fakes/fake_account_deletion_gateway.dart';

const _profilesTable = TableSchema(
  id: 'profiles',
  name: 'Profiles',
  columns: <ColumnSchema>[
    ColumnSchema(key: 'userId', type: ColumnType.text),
    ColumnSchema(key: 'avatarFileId', type: ColumnType.text, isRequired: false),
  ],
  ownership: TableOwnership(
    userIdColumn: 'userId',
    fileRefs: <OwnedFileRef>[
      OwnedFileRef(column: 'avatarFileId', bucketId: 'avatars'),
    ],
  ),
);

const _unownedTable = TableSchema(
  id: 'public_posts',
  name: 'Public Posts',
  columns: <ColumnSchema>[ColumnSchema(key: 'title', type: ColumnType.text)],
);

const _schema = AppwriteSchema(
  databaseId: 'main',
  databaseName: 'Main',
  tables: <TableSchema>[_profilesTable, _unownedTable],
  buckets: <BucketSchema>[BucketSchema(id: 'avatars', name: 'Avatars')],
  functions: <FunctionSchema>[],
);

const ada = TeamActor(userId: 'ada', email: 'ada@example.com');
const linus = TeamActor(userId: 'linus', email: 'linus@example.com');
const grace = TeamActor(userId: 'grace', email: 'grace@example.com');

/// Ada owns "Acme" (Grace admin, Linus member) and "Side Project".
Future<({TeamEngine engine, InMemoryTeamStore store, Team acme})>
_world() async {
  final store = InMemoryTeamStore();
  final engine = TeamEngine(store: store);
  final acme = await engine.createTeam(ada, 'Acme');
  await engine.createTeam(ada, 'Side Project');
  for (final (actor, role) in [
    (grace, TeamRoles.admin),
    (linus, TeamRoles.member),
  ]) {
    final invitation = await engine.invite(
      ada,
      acme.id,
      email: actor.email,
      role: role,
    );
    await engine.acceptInvitation(actor, invitation.id);
  }

  return (engine: engine, store: store, acme: acme);
}

void main() {
  test('deletes owned rows, referenced files, then the user', () async {
    final gateway = FakeAccountDeletionGateway()
      ..seedRows(
        tableId: 'profiles',
        userId: 'user-1',
        rows: <Map<String, dynamic>>[
          <String, dynamic>{'userId': 'user-1', 'avatarFileId': 'file-1'},
        ],
      );
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final result = await service.deleteAccount('user-1');

    expect(result.userId, 'user-1');
    expect(result.userDeleted, isTrue);
    expect(result.removedRows, <String, int>{'profiles': 1});
    expect(result.removedFiles, <String, int>{'avatars': 1});
    expect(gateway.deletedFiles, <String>['avatars/file-1']);
    expect(gateway.deletedUsers, <String>['user-1']);
  });

  test('never touches tables with no ownership declaration', () async {
    final gateway = FakeAccountDeletionGateway();
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final result = await service.deleteAccount('user-1');

    expect(result.removedRows, isEmpty);
    expect(gateway.deletedUsers, <String>['user-1']);
  });

  test('skips a null file reference without deleting anything', () async {
    final gateway = FakeAccountDeletionGateway()
      ..seedRows(
        tableId: 'profiles',
        userId: 'user-1',
        rows: <Map<String, dynamic>>[
          <String, dynamic>{'userId': 'user-1', 'avatarFileId': null},
        ],
      );
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final result = await service.deleteAccount('user-1');

    expect(result.removedRows, <String, int>{'profiles': 1});
    expect(result.removedFiles, isEmpty);
    expect(gateway.deletedFiles, isEmpty);
  });

  test('reports userDeleted: false when Users.delete fails, without '
      'throwing', () async {
    final gateway = FakeAccountDeletionGateway()
      ..deleteUserError = Exception('boom');
    final service = DeletionService(
      gateway: gateway,
      schema: _schema,
      teams: TeamEngine(store: InMemoryTeamStore()),
    );

    final result = await service.deleteAccount('user-1');

    expect(result.userDeleted, isFalse);
  });

  group('team ownership', () {
    test('an owner is refused, naming every owned team, and nothing is '
        'deleted', () async {
      final w = await _world();
      final gateway = FakeAccountDeletionGateway()
        ..seedRows(
          tableId: 'profiles',
          userId: 'ada',
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'userId': 'ada', 'avatarFileId': 'file-1'},
          ],
        );
      final service = DeletionService(
        gateway: gateway,
        schema: _schema,
        teams: w.engine,
      );

      await expectLater(
        service.deleteAccount('ada'),
        throwsA(
          isA<AccountOwnsTeamsException>().having(
            (e) => e.teamNames,
            'teamNames',
            <String>['Acme', 'Side Project'],
          ),
        ),
      );

      expect(gateway.deletedUsers, isEmpty);
      expect(gateway.deletedFiles, isEmpty);
      expect(gateway.rowsByTable['profiles']?['ada'], isNotEmpty);
    });
  });

  group('deleting a non-owner', () {
    test(
      'an admin and a member delete fine, and the history survives',
      () async {
        final w = await _world();
        final before = await w.store.eventsOfTeam(w.acme.id);

        for (final userId in ['grace', 'linus']) {
          final gateway = FakeAccountDeletionGateway();
          final service = DeletionService(
            gateway: gateway,
            schema: _schema,
            teams: w.engine,
          );

          final result = await service.deleteAccount(userId);

          expect(result.userDeleted, isTrue);
          expect(gateway.deletedUsers, <String>[userId]);
        }

        final after = await w.store.eventsOfTeam(w.acme.id);
        expect(after, hasLength(before.length));
        expect(
          after.where(
            (e) => e.subjectUserId == 'linus' || e.subjectUserId == 'grace',
          ),
          isNotEmpty,
        );
      },
    );
  });
}
