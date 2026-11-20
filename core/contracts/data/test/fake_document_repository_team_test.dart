import 'package:data/data.dart';
import 'package:teams/teams.dart';
import 'package:test/test.dart';

const _ada = TeamActor(userId: 'ada', email: 'ada@example.com');
const _grace = TeamActor(userId: 'grace', email: 'grace@example.com');
const _linus = TeamActor(userId: 'linus', email: 'linus@example.com');
const _eve = TeamActor(userId: 'eve', email: 'eve@example.com');

Future<void> _join(
  FakeTeamBackend backend,
  Team team,
  TeamActor who,
  String role,
) async {
  final invitation = await backend
      .serviceFor(_ada)
      .invite(team.id, email: who.email, role: role);
  await backend.serviceFor(who).acceptInvitation(invitation.id);
}

/// Ada owns Acme (Grace its admin, Linus a member); Eve owns Globex; all
/// share one collection.
// A test fixture named for what it is, not for the file.
// ignore: solid_lints/prefer_match_file_name
class _World {
  _World._(this.backend, this.acme, this.globex, this._table);

  final FakeTeamBackend backend;
  final Team acme;
  final Team globex;
  final FakeDocumentRepository _table;

  static Future<_World> create() async {
    final backend = FakeTeamBackend();
    final acme = await backend.serviceFor(_ada).createTeam('Acme');
    final globex = await backend.serviceFor(_eve).createTeam('Globex');
    await _join(backend, acme, _grace, TeamRoles.admin);
    await _join(backend, acme, _linus, TeamRoles.member);

    return _World._(
      backend,
      acme,
      globex,
      FakeDocumentRepository(teams: backend, userId: 'ada'),
    );
  }

  FakeDocumentRepository as(String user) => _table.asUser(user);
}

void main() {
  test('team rows: every member reads them, and nobody else', () async {
    final w = await _World.create();
    final row = await w.as('linus').create(<String, dynamic>{
      'title': 'shared',
    }, scope: TeamScope(w.acme.id));

    expect((await w.as('ada').read(row.id)).data['title'], 'shared');
    expect((await w.as('grace').read(row.id)).data['title'], 'shared');
    expect(row.data['teamId'], w.acme.id);
    expect(row.data['userId'], 'linus');
    // Another tenant's owner:
    expect(() => w.as('eve').read(row.id), throwsA(isA<DataPermissionError>()));
    expect(
      () => w.as('eve').update(row.id, <String, dynamic>{}),
      throwsA(isA<DataPermissionError>()),
    );
    expect(
      () => w.as('eve').delete(row.id),
      throwsA(isA<DataPermissionError>()),
    );
  });

  test('team rows: a member of one team never lists another team', () async {
    final w = await _World.create();
    await w.as('ada').create(<String, dynamic>{
      'title': 'acme row',
    }, scope: TeamScope(w.acme.id));
    await w.as('eve').create(<String, dynamic>{
      'title': 'globex row',
    }, scope: TeamScope(w.globex.id));

    final own = await w
        .as('linus')
        .query(const DataQuery(), TeamScope(w.acme.id));
    // Asking for the other team's scope still yields nothing.
    final probe = await w
        .as('linus')
        .query(const DataQuery(), TeamScope(w.globex.id));

    expect(own.map((d) => d.data['title']), ['acme row']);
    expect(probe, isEmpty);
  });

  test('team rows: a removed member loses access at once', () async {
    final w = await _World.create();
    final row = await w.as('ada').create(<String, dynamic>{
      'title': 'a',
    }, scope: TeamScope(w.acme.id));
    await w.as('linus').read(row.id);

    await w.backend.serviceFor(_ada).removeMember(w.acme.id, userId: 'linus');

    expect(
      () => w.as('linus').read(row.id),
      throwsA(isA<DataPermissionError>()),
    );
    expect(
      await w.as('linus').query(const DataQuery(), TeamScope(w.acme.id)),
      isEmpty,
    );
  });

  test('team rows: no creating one in a team you are not in', () async {
    final w = await _World.create();

    expect(
      () =>
          w.as('eve').create(<String, dynamic>{}, scope: TeamScope(w.acme.id)),
      throwsA(isA<DataPermissionError>()),
    );
  });

  test(
    'role rows: admins-only is hidden from members, seen by owner',
    () async {
      final w = await _World.create();
      final row = await w.as('grace').create(<String, dynamic>{
        'title': 'budget',
      }, scope: TeamScope(w.acme.id, readRoles: {TeamRoles.admin}));

      expect((await w.as('grace').read(row.id)).id, row.id);
      expect(
        (await w.as('ada').read(row.id)).id,
        row.id,
      ); // owner implies admin
      expect(
        () => w.as('linus').read(row.id),
        throwsA(isA<DataPermissionError>()),
      );
      expect(
        await w.as('linus').query(const DataQuery(), TeamScope(w.acme.id)),
        isEmpty,
      );
    },
  );

  test('role rows: a member cannot create an admins-only row', () async {
    final w = await _World.create();

    expect(
      () => w
          .as('linus')
          .create(
            <String, dynamic>{},
            scope: TeamScope(w.acme.id, readRoles: {TeamRoles.admin}),
          ),
      throwsA(isA<DataPermissionError>()),
    );
  });

  test('role rows: members read, only admins write', () async {
    final w = await _World.create();
    final row = await w.as('grace').create(
      <String, dynamic>{'title': 'policy'},
      scope: TeamScope(
        w.acme.id,
        writeRoles: {TeamRoles.admin},
        readRoles: {TeamRoles.member},
      ),
    );

    expect((await w.as('linus').read(row.id)).id, row.id);
    expect(
      () => w.as('linus').update(row.id, <String, dynamic>{'title': 'x'}),
      throwsA(isA<DataPermissionError>()),
    );
    expect(
      () => w.as('linus').delete(row.id),
      throwsA(isA<DataPermissionError>()),
    );
    final updated = await w.as('grace').update(row.id, <String, dynamic>{
      'title': 'new',
    });
    expect(updated.data['title'], 'new');
    expect(updated.data['teamId'], w.acme.id, reason: 'scope column is kept');
  });

  test('user rows: private to their creator, even inside a team', () async {
    final w = await _World.create();
    final row = await w.as('linus').create(<String, dynamic>{'title': 'mine'});

    expect(() => w.as('ada').read(row.id), throwsA(isA<DataPermissionError>()));
    expect(await w.as('ada').query(), isEmpty);
    expect((await w.as('linus').query()).single.id, row.id);
  });

  test('the single-user fake without a userId is unchanged', () async {
    final solo = FakeDocumentRepository();
    final row = await solo.create(<String, dynamic>{'title': 'x'});

    expect(row.data, <String, dynamic>{'title': 'x'});
    expect((await solo.query()).single.id, row.id);
  });
}
