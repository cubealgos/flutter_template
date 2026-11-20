// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it — see `backend/appwrite/README.md`). Tagged `integration`
// so it's excluded from `melos run test`'s default run; run via `melos run
// test:integration:backend_appwrite` (or this file alone:
// `cd backend/appwrite/adapters && fvm flutter test --tags integration
// --run-skipped test/integration/appwrite_teams_integration_test.dart`).
//
// Team tenancy, end to end against the real thing: provisions
// the schema, deploys the `api` router (with its `team_admin` action) for
// real, signs in admin-created users
// (email marked verified, which `team_admin` requires) and proves that
//   - a member of team A can neither read, list nor write team B's rows;
//   - removing a member takes their access away at once;
//   - role-scoped rows (`readRoles: {admin}`) are hidden from plain members;
//   - the one-owner invariant holds, and holds against a client that skips
//     the Function and calls the Teams SDK directly;
//   - ownership transfer works and the history outlives a removed member.
@Timeout(Duration(minutes: 6))
@Tags(['integration'])
library;

import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:auth/auth.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as server;
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import 'support/deploy_api.dart';
import 'support/path_provider_channel.dart';

// `setUpAll` populates both before any test runs; there is no earlier
// point to initialize them without `late`.
// ignore: solid_lints/avoid_late_keyword
late BackendEnv _env;
// Same reasoning as `_env`.
// ignore: solid_lints/avoid_late_keyword
late server.Client _adminClient;

/// One signed-in, email-verified test user with its own client.
// A test fixture named for what it is, not for the file.
// ignore: solid_lints/prefer_match_file_name
class _Person {
  _Person(this.client, this.userId, this.email)
    : teams = AppwriteTeamService(client),
      notes = AppwriteDocumentRepository(
        client,
        databaseId: templateSchema.databaseId,
        tableId: 'team_notes',
      );

  final Client client;
  final String userId;
  final String email;
  final AppwriteTeamService teams;
  final AppwriteDocumentRepository notes;
}

void main() {
  final createdTeamIds = <String>[];
  final createdUserIds = <String>[];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    initPathProviderChannel('backend_appwrite_teams_integration_');
    HttpOverrides.global = null;
    _env = BackendEnv.load();
    _adminClient = buildClient(_env);
    await Provisioner(
      admin: DartAppwriteAdmin(_adminClient),
      schema: templateSchema,
    ).run();
    await deployApi(_adminClient);
  });

  tearDownAll(() async {
    for (final id in createdTeamIds) {
      await _cleanupTeam(id);
    }
    for (final id in createdUserIds) {
      await _ignoringAppwrite(
        () => server.Users(_adminClient).delete(userId: id),
      );
    }
  });

  Future<_Person> person(String name) async {
    final email = '$name-${DateTime.now().microsecondsSinceEpoch}@example.com';
    final users = server.Users(_adminClient);
    final user = await users.create(userId: server.ID.unique(), email: email);
    createdUserIds.add(user.$id);
    // `team_admin` matches invitations by email, so it needs it verified.
    await users.updateEmailVerification(
      userId: user.$id,
      emailVerification: true,
    );
    final token = await users.createToken(userId: user.$id);
    final client = Client()
        .setEndpoint(_env.endpoint)
        .setProject(_env.projectId);
    await AppwriteAuthService(client).verifyEmailCode(
      EmailCodeRequest(userId: user.$id, email: email),
      token.secret,
    );

    return _Person(client, user.$id, email);
  }

  Future<Team> teamOf(_Person owner) async {
    final team = await owner.teams.createTeam('Integration');
    createdTeamIds.add(team.id);

    return team;
  }

  Future<void> join(Team team, _Person owner, _Person who, String role) async {
    final invitation = await owner.teams.invite(
      team.id,
      email: who.email,
      role: role,
    );
    await who.teams.acceptInvitation(invitation.id);
  }

  test('a member of team A cannot read, list or write team B rows', () async {
    final alice = await person('alice');
    final bob = await person('bob');
    final teamA = await teamOf(alice);
    final teamB = await teamOf(bob);
    final noteA = await alice.notes.create(<String, dynamic>{
      'body': 'A',
    }, scope: TeamScope(teamA.id));
    final noteB = await bob.notes.create(<String, dynamic>{
      'body': 'B',
    }, scope: TeamScope(teamB.id));

    // Each sees their own team's row...
    expect((await alice.notes.read(noteA.id)).data['body'], 'A');
    expect(
      (await alice.notes.query(
        const DataQuery(),
        TeamScope(teamA.id),
      )).map((d) => d.id),
      [noteA.id],
    );
    // ...and nobody else's.
    await expectLater(
      () => bob.notes.read(noteA.id),
      throwsA(isA<DataError>()),
    );
    await expectLater(
      () => alice.notes.read(noteB.id),
      throwsA(isA<DataError>()),
    );
    expect(
      await bob.notes.query(const DataQuery(), TeamScope(teamA.id)),
      isEmpty,
    );
    await expectLater(
      () => bob.notes.update(noteA.id, <String, dynamic>{'body': 'x'}),
      throwsA(isA<DataError>()),
    );
    await expectLater(
      () => bob.notes.delete(noteA.id),
      throwsA(isA<DataError>()),
    );
    await expectLater(
      () => bob.notes.create(<String, dynamic>{
        'body': 'planted',
      }, scope: TeamScope(teamA.id)),
      throwsA(isA<DataPermissionError>()),
    );
    // A non-member also gets nothing from the team API.
    await expectLater(
      () => bob.teams.listMembers(teamA.id),
      throwsA(isA<TeamNotFoundError>()),
    );
  }, tags: 'integration');

  test('removing a member takes their access away at once', () async {
    final alice = await person('alice');
    final carol = await person('carol');
    final team = await teamOf(alice);
    await join(team, alice, carol, TeamRoles.member);
    final note = await alice.notes.create(<String, dynamic>{
      'body': 'shared',
    }, scope: TeamScope(team.id));
    expect((await carol.notes.read(note.id)).data['body'], 'shared');
    expect((await carol.teams.listTeams()).single.id, team.id);

    await alice.teams.removeMember(team.id, userId: carol.userId);

    await expectLater(
      () => carol.notes.read(note.id),
      throwsA(isA<DataError>()),
    );
    expect(await carol.teams.listTeams(), isEmpty);
  }, tags: 'integration');

  test('role-scoped rows are hidden from plain members', () async {
    final alice = await person('alice'); // owner
    final dave = await person('dave'); // admin
    final erin = await person('erin'); // member
    final team = await teamOf(alice);
    await join(team, alice, dave, TeamRoles.admin);
    await join(team, alice, erin, TeamRoles.member);

    final adminsOnly = await dave.notes.create(<String, dynamic>{
      'body': 'budget',
    }, scope: TeamScope(team.id, readRoles: <String>{TeamRoles.admin}));

    expect((await dave.notes.read(adminsOnly.id)).data['body'], 'budget');
    expect((await alice.notes.read(adminsOnly.id)).data['body'], 'budget');
    await expectLater(
      () => erin.notes.read(adminsOnly.id),
      throwsA(isA<DataError>()),
    );
    expect(
      await erin.notes.query(const DataQuery(), TeamScope(team.id)),
      isEmpty,
    );
    // A member can't mint an admins-only row (Appwrite only lets a client
    // grant roles it holds).
    await expectLater(
      () => erin.notes.create(<String, dynamic>{
        'body': 'forged',
      }, scope: TeamScope(team.id, readRoles: <String>{TeamRoles.admin})),
      throwsA(isA<DataPermissionError>()),
    );
  }, tags: 'integration');

  test('exactly one owner: the Function refuses a second one, and so does '
      'the Teams SDK called directly', () async {
    final alice = await person('alice');
    final frank = await person('frank');
    final team = await teamOf(alice);
    await join(team, alice, frank, TeamRoles.member);

    await expectLater(
      () => alice.teams.changeRole(
        team.id,
        userId: frank.userId,
        role: TeamRoles.owner,
      ),
      throwsA(isA<TeamInvariantError>()),
    );
    await expectLater(
      () => alice.teams.invite(
        team.id,
        email: 'x@example.com',
        role: TeamRoles.owner,
      ),
      throwsA(isA<TeamInvariantError>()),
    );
    await expectLater(
      () => alice.teams.leaveTeam(team.id),
      throwsA(isA<TeamInvariantError>()),
    );

    await _expectNativeBypassRefused(alice, frank, team);
    final owners = (await alice.teams.listMembers(team.id))
        .where((m) => m.role == TeamRoles.owner);
    expect(owners.map((m) => m.userId), [alice.userId]);
  }, tags: 'integration');

  test('ownership transfer moves the one owner role; the history outlives '
      'a removed member', () async {
    final alice = await person('alice');
    final gina = await person('gina');
    final team = await teamOf(alice);
    await join(team, alice, gina, TeamRoles.admin);

    await alice.teams.transferOwnership(team.id, toUserId: gina.userId);

    final roles = {
      for (final m in await gina.teams.listMembers(team.id)) m.userId: m.role,
    };
    expect(roles, {
      alice.userId: TeamRoles.admin,
      gina.userId: TeamRoles.owner,
    });
    await expectLater(
      () => alice.teams.transferOwnership(team.id, toUserId: alice.userId),
      throwsA(isA<TeamPermissionError>()),
    );

    await gina.teams.removeMember(team.id, userId: alice.userId);
    final history = await gina.teams.history(team.id);

    expect(history.map((e) => e.type), <MembershipEventType>[
      MembershipEventType.teamCreated,
      MembershipEventType.invited,
      MembershipEventType.accepted,
      MembershipEventType.ownershipTransferred,
      MembershipEventType.removed,
    ]);
    final removal = history.last;
    expect(removal.actorUserId, gina.userId);
    expect(removal.subjectUserId, alice.userId);
    expect(removal.subjectEmail, alice.email);
  }, tags: 'integration');
}

/// Mocks the `path_provider` platform channel `appwrite`'s `Client` needs —
/// see `appwrite_adapters_integration_test.dart`'s `setUpAll`.
Future<void> _ignoringAppwrite(Future<void> Function() action) async {
  try {
    await action();
  } on server.AppwriteException {
    // Already gone — the happy path.
  }
}

/// Deletes [teamId] and every invitation, event and note row that names it.
Future<void> _cleanupTeam(String teamId) async {
  await _ignoringAppwrite(
    () => server.Teams(_adminClient).delete(teamId: teamId),
  );
  for (final table in <String>[
    'team_invitations',
    'team_membership_events',
    'team_notes',
  ]) {
    await _ignoringAppwrite(
      () => server.TablesDB(_adminClient).deleteRows(
        databaseId: templateSchema.databaseId,
        tableId: table,
        queries: <String>[server.Query.equal('teamId', teamId)],
      ),
    );
  }
}

/// Skipping the Function: the owner holds `tenant_owner`, not Appwrite's own
/// `owner` role, so the Teams SDK refuses her a direct membership change.
///
/// **Why Frank's ID comes from the action.** Verified live: the
/// owner's own `Teams.listMemberships` returns the other member with an
/// *empty* `userId` (Appwrite's membership privacy hides member details from
/// anyone who is not a native `owner`), so `userId == frank` never matches
/// there. The `team_admin` action reads with the API key and returns the
/// native ID as `Membership.membershipId`. The harness key has no `teams.*`
/// scopes, and a made-up ID would make a 404 pass as a "refusal".
///
/// **What each call proves** (Appwrite server 2.x, `Teams/Http/Memberships/`
/// `Update.php` lines 90-117 and `Create.php` lines 111-267, tag 2.3.0):
/// - `updateMembership` checks authorization (`hasRole('team:<id>/owner')`,
///   otherwise `user_unauthorized` 401) with no SMTP involved, so its refusal
///   proves a `tenant_owner` holder cannot re-role anyone.
/// - `createMembership` never reaches its own code: the route is labelled
///   `auth.type: invites` (Create.php line 61), and the provisioner disables
///   the `invites` auth method, so Appwrite refuses every client
///   invitation up front with `user_auth_method_unsupported` (501), before
///   the SMTP check (line 127) and the owner check (lines 264-267), and
///   before any invitee user is created. That is a project-wide guarantee,
///   stronger than the owner check, and it is what this asserts.
Future<void> _expectNativeBypassRefused(
  _Person alice,
  _Person frank,
  Team team,
) async {
  final sdk = Teams(alice.client);
  final members = await alice.teams.listMembers(team.id);
  final sdkView = await _describeOwnerSdkView(sdk, team.id);
  final diagnostic =
      'the action lists ${_describe(members.map(_row))}; '
      "the owner's own Teams SDK call sees $sdkView";
  final frankId = members
      .firstWhere((m) => m.userId == frank.userId)
      .membershipId;
  if (frankId == null) throw StateError('No native membership ID: $diagnostic');
  final updateError = await _refusal(
    () => sdk.updateMembership(
      teamId: team.id,
      membershipId: frankId,
      roles: <String>['owner'],
    ),
  );
  expect(updateError.type, _userUnauthorized, reason: diagnostic);
  expect(updateError.code, _unauthorized, reason: diagnostic);
  final createError = await _refusal(
    () => sdk.createMembership(
      teamId: team.id,
      roles: <String>['owner'],
      email: 'someone@example.com',
    ),
  );
  // See the dartdoc: client invitations are disabled project-wide.
  expect(
    createError.type,
    _authMethodUnsupported,
    reason:
        '$diagnostic; create error: ${createError.code} '
        '${createError.type}',
  );
}

const String _userUnauthorized = 'user_unauthorized';
const String _authMethodUnsupported = 'user_auth_method_unsupported';

/// What the owner's raw `Teams.listMemberships` returns, or the error.
Future<String> _describeOwnerSdkView(Teams sdk, String teamId) async {
  try {
    final list = await sdk.listMemberships(teamId: teamId);

    return _describe(list.memberships.map(_clientRow));
  } on AppwriteException catch (e) {
    return 'error ${e.code}: ${e.message}';
  }
}

const int _unauthorized = 401;

typedef _Seen = ({String userId, List<String> roles, bool confirm});

_Seen _row(Membership m) =>
    (userId: m.userId, roles: <String>[m.role], confirm: true);

_Seen _clientRow(models.Membership m) =>
    (userId: m.userId, roles: m.roles, confirm: m.confirm);

/// A one-line description of [seen], for failure messages.
String _describe(Iterable<_Seen> seen) =>
    [for (final m in seen) '${m.userId}${m.roles}/confirm=${m.confirm}']
        .join(', ');

/// Runs [call], which must fail with an [AppwriteException], and returns it.
Future<AppwriteException> _refusal(Future<Object?> Function() call) async {
  try {
    await call();
  } on AppwriteException catch (e) {
    return e;
  }
  fail('the call was not refused');
}
