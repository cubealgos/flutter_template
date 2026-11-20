import 'package:teams/teams.dart';
import 'package:test/test.dart';

const _ada = TeamActor(userId: 'ada', email: 'Ada@Example.com');
const _grace = TeamActor(userId: 'grace', email: 'grace@example.com');
const _eightDays = Duration(days: 8);
const _threeMembers = 3;
const _twoMembers = 2;
const _twoOwners = 2;
const _oneHour = Duration(hours: 1);
const _linus = TeamActor(userId: 'linus', email: 'linus@example.com');

/// Ada owns a team with Grace as admin and Linus as member.
Future<
  ({
    FakeTeamBackend backend,
    FakeTeamService ada,
    FakeTeamService grace,
    FakeTeamService linus,
    Team team,
  })
>
_staffedTeam() async {
  final backend = FakeTeamBackend();
  final ada = backend.serviceFor(_ada);
  final grace = backend.serviceFor(_grace);
  final linus = backend.serviceFor(_linus);
  final team = await ada.createTeam('Acme');
  for (final (who, actor, role) in [
    (grace, _grace, TeamRoles.admin),
    (linus, _linus, TeamRoles.member),
  ]) {
    final invitation = await ada.invite(
      team.id,
      email: actor.email,
      role: role,
    );
    await who.acceptInvitation(invitation.id);
  }

  return (backend: backend, ada: ada, grace: grace, linus: linus, team: team);
}

Future<int> _owners(FakeTeamService service, String teamId) async =>
    (await service.listMembers(
      teamId,
    )).where((m) => m.role == TeamRoles.owner).length;

void main() {
  test('create and invite: the creator becomes the one owner', () async {
    final backend = FakeTeamBackend();
    final ada = backend.serviceFor(_ada);

    final team = await ada.createTeam('  Acme ');

    expect(team.name, 'Acme');
    final members = await ada.listMembers(team.id);
    expect(members.single.role, TeamRoles.owner);
    expect(members.single.email, 'ada@example.com');
    expect((await ada.listTeams()).single.id, team.id);
  });

  test('create and invite: a blank name is refused', () {
    final ada = FakeTeamBackend().serviceFor(_ada);

    expect(() => ada.createTeam('  '), throwsA(isA<TeamInvariantError>()));
  });

  test(
    'create and invite: invite then accept joins with the invited role',
    () async {
      final s = await _staffedTeam();

      final members = await s.ada.listMembers(s.team.id);

      expect(members.map((m) => m.role), [
        TeamRoles.owner,
        TeamRoles.admin,
        TeamRoles.member,
      ]);
    },
  );

  test(
    'an invitation is only visible to and acceptable by its email',
    () async {
      final backend = FakeTeamBackend();
      final ada = backend.serviceFor(_ada);
      final team = await ada.createTeam('Acme');
      final invitation = await ada.invite(
        team.id,
        email: 'Grace@example.com',
        role: TeamRoles.member,
      );

      expect(await backend.serviceFor(_linus).listMyInvitations(), isEmpty);
      expect(
        () => backend.serviceFor(_linus).acceptInvitation(invitation.id),
        throwsA(isA<TeamNotFoundError>()),
      );
      expect(
        (await backend.serviceFor(_grace).listMyInvitations()).single.id,
        invitation.id,
      );
    },
  );

  test('create and invite: an owner role can never be invited', () async {
    final backend = FakeTeamBackend();
    final ada = backend.serviceFor(_ada);
    final team = await ada.createTeam('Acme');

    expect(
      () => ada.invite(team.id, email: 'g@example.com', role: TeamRoles.owner),
      throwsA(isA<TeamInvariantError>()),
    );
    expect(
      () => ada.invite(team.id, email: 'g@example.com', role: 'wizard'),
      throwsA(isA<TeamInvariantError>()),
    );
  });

  test('create and invite: the owner role stays ungrantable even if an app '
      'lists it as assignable', () async {
    final backend = FakeTeamBackend(
      assignableRoles: {TeamRoles.admin, TeamRoles.member, TeamRoles.owner},
    );
    final ada = backend.serviceFor(_ada);
    final team = await ada.createTeam('Acme');
    final invitation = await ada.invite(
      team.id,
      email: _grace.email,
      role: TeamRoles.member,
    );
    await backend.serviceFor(_grace).acceptInvitation(invitation.id);

    await expectLater(
      () => ada.invite(team.id, email: 'x@example.com', role: TeamRoles.owner),
      throwsA(isA<TeamInvariantError>()),
    );
    await expectLater(
      () => ada.changeRole(team.id, userId: 'grace', role: TeamRoles.owner),
      throwsA(isA<TeamInvariantError>()),
    );
    expect(await _owners(ada, team.id), 1);
  });

  test(
    'create and invite: a duplicate or already-member invitation is refused',
    () async {
      final s = await _staffedTeam();

      expect(
        () => s.ada.invite(
          s.team.id,
          email: _grace.email,
          role: TeamRoles.member,
        ),
        throwsA(isA<TeamInvitationError>()),
      );
      await s.ada.invite(s.team.id, email: 'x@example.com', role: 'member');
      expect(
        () => s.ada.invite(s.team.id, email: 'X@example.com', role: 'member'),
        throwsA(isA<TeamInvitationError>()),
      );
    },
  );

  test(
    'create and invite: an app-defined role works when the backend allows it',
    () async {
      final backend = FakeTeamBackend(
        assignableRoles: {TeamRoles.admin, TeamRoles.member, 'auditor'},
      );
      final ada = backend.serviceFor(_ada);
      final team = await ada.createTeam('Acme');

      final invitation = await ada.invite(
        team.id,
        email: _grace.email,
        role: 'auditor',
      );
      final joined = await backend
          .serviceFor(_grace)
          .acceptInvitation(invitation.id);

      expect(joined.role, 'auditor');
      expect(await backend.rolesOf(userId: 'grace', teamId: team.id), {
        'auditor',
        TeamRoles.member,
      });
    },
  );

  test(
    'expire and revoke: an invitation expires and cannot be accepted',
    () async {
      final backend = FakeTeamBackend();
      final ada = backend.serviceFor(_ada);
      final team = await ada.createTeam('Acme');
      final invitation = await ada.invite(
        team.id,
        email: _grace.email,
        role: TeamRoles.member,
      );

      backend.advance(_eightDays);

      final grace = backend.serviceFor(_grace);
      expect(await grace.listMyInvitations(), isEmpty);
      expect(
        () => grace.acceptInvitation(invitation.id),
        throwsA(isA<TeamInvitationError>()),
      );
      expect(
        (await ada.listInvitations(team.id)).single.status,
        InvitationStatus.expired,
      );
      expect(
        (await ada.history(team.id)).last,
        isA<MembershipEvent>()
            .having((e) => e.type, 'type', MembershipEventType.expired)
            .having((e) => e.actorUserId, 'actor', TeamEngine.systemActorId),
      );
    },
  );

  test(
    'revoke: a revoked invitation cannot be accepted or revoked again',
    () async {
      final backend = FakeTeamBackend();
      final ada = backend.serviceFor(_ada);
      final team = await ada.createTeam('Acme');
      final invitation = await ada.invite(
        team.id,
        email: _grace.email,
        role: TeamRoles.member,
      );

      await ada.revokeInvitation(invitation.id);

      expect(
        () => backend.serviceFor(_grace).acceptInvitation(invitation.id),
        throwsA(isA<TeamInvitationError>()),
      );
      expect(
        () => ada.revokeInvitation(invitation.id),
        throwsA(isA<TeamInvitationError>()),
      );
    },
  );

  test(
    'roles and removal: a member can neither invite nor read the history',
    () async {
      final s = await _staffedTeam();

      expect(
        () => s.linus.invite(s.team.id, email: 'x@example.com', role: 'member'),
        throwsA(isA<TeamPermissionError>()),
      );
      expect(
        () => s.linus.history(s.team.id),
        throwsA(isA<TeamPermissionError>()),
      );
      expect(await s.linus.listMembers(s.team.id), hasLength(_threeMembers));
    },
  );

  test(
    'roles and removal: an admin manages members but not other admins or owner',
    () async {
      final s = await _staffedTeam();

      expect(
        () => s.grace.invite(s.team.id, email: 'x@example.com', role: 'admin'),
        throwsA(isA<TeamPermissionError>()),
      );
      expect(
        () => s.grace.removeMember(s.team.id, userId: 'ada'),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(
        () => s.grace.changeRole(
          s.team.id,
          userId: 'linus',
          role: TeamRoles.admin,
        ),
        throwsA(isA<TeamPermissionError>()),
      );
      await s.grace.removeMember(s.team.id, userId: 'linus');
      expect(await s.ada.listMembers(s.team.id), hasLength(_twoMembers));
    },
  );

  test(
    'roles and removal: only the owner promotes to admin, and never to owner',
    () async {
      final s = await _staffedTeam();

      final promoted = await s.ada.changeRole(
        s.team.id,
        userId: 'linus',
        role: TeamRoles.admin,
      );

      expect(promoted.role, TeamRoles.admin);
      expect(
        () =>
            s.ada.changeRole(s.team.id, userId: 'linus', role: TeamRoles.owner),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(
        () =>
            s.ada.changeRole(s.team.id, userId: 'ada', role: TeamRoles.member),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(await _owners(s.ada, s.team.id), 1);
    },
  );

  test(
    'roles and removal: the owner cannot be removed and cannot leave',
    () async {
      final s = await _staffedTeam();

      expect(
        () => s.ada.removeMember(s.team.id, userId: 'ada'),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(
        () => s.ada.leaveTeam(s.team.id),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(await _owners(s.ada, s.team.id), 1);
    },
  );

  test(
    'roles and removal: a member can leave and then no longer sees the team',
    () async {
      final s = await _staffedTeam();

      await s.linus.leaveTeam(s.team.id);

      expect(await s.linus.listTeams(), isEmpty);
      expect(
        () => s.linus.listMembers(s.team.id),
        throwsA(isA<TeamNotFoundError>()),
      );
    },
  );

  test(
    'removal: a stranger sees a team as not found, never forbidden',
    () async {
      final s = await _staffedTeam();
      final stranger = s.backend.serviceFor(
        const TeamActor(userId: 'eve', email: 'eve@example.com'),
      );

      expect(
        () => stranger.listMembers(s.team.id),
        throwsA(isA<TeamNotFoundError>()),
      );
      expect(
        () => stranger.removeMember(s.team.id, userId: 'linus'),
        throwsA(isA<TeamNotFoundError>()),
      );
    },
  );

  test(
    'ownership transfer: moves the one owner role and demotes the old owner',
    () async {
      final s = await _staffedTeam();

      await s.ada.transferOwnership(s.team.id, toUserId: 'linus');

      final roles = {
        for (final m in await s.ada.listMembers(s.team.id)) m.userId: m.role,
      };
      expect(roles, {
        'ada': TeamRoles.admin,
        'grace': TeamRoles.admin,
        'linus': TeamRoles.owner,
      });
      expect(
        () => s.ada.transferOwnership(s.team.id, toUserId: 'grace'),
        throwsA(isA<TeamPermissionError>()),
      );
    },
  );

  test(
    'ownership transfer: is refused for self, a non-member and a non-owner',
    () async {
      final s = await _staffedTeam();

      expect(
        () => s.ada.transferOwnership(s.team.id, toUserId: 'ada'),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(
        () => s.ada.transferOwnership(s.team.id, toUserId: 'nobody'),
        throwsA(isA<TeamInvariantError>()),
      );
      expect(
        () => s.grace.transferOwnership(s.team.id, toUserId: 'grace'),
        throwsA(isA<TeamPermissionError>()),
      );
      expect(await _owners(s.ada, s.team.id), 1);
    },
  );

  test(
    'ownership transfer: an interrupted transfer is repaired by the next call',
    () async {
      final s = await _staffedTeam();
      await s.ada.transferOwnership(s.team.id, toUserId: 'linus');
      // Simulate a crash before the old owner was demoted: ada owns again.
      final ada = (await s.ada.listMembers(
        s.team.id,
      )).firstWhere((m) => m.userId == 'ada');
      await s.backend.store.saveMembership(ada.withRole(TeamRoles.owner));
      expect(await _owners(s.ada, s.team.id), _twoOwners);

      await s.linus.changeRole(
        s.team.id,
        userId: 'grace',
        role: TeamRoles.member,
      );

      final roles = {
        for (final m in await s.ada.listMembers(s.team.id)) m.userId: m.role,
      };
      expect(roles['linus'], TeamRoles.owner);
      expect(roles['ada'], TeamRoles.admin);
    },
  );

  test('history: records every event with actor and time, in order', () async {
    final s = await _staffedTeam();
    s.backend.advance(_oneHour);
    await s.ada.changeRole(s.team.id, userId: 'linus', role: 'admin');
    await s.ada.transferOwnership(s.team.id, toUserId: 'linus');

    final history = await s.linus.history(s.team.id);

    expect(history.map((e) => e.type), [
      MembershipEventType.teamCreated,
      MembershipEventType.invited,
      MembershipEventType.accepted,
      MembershipEventType.invited,
      MembershipEventType.accepted,
      MembershipEventType.roleChanged,
      MembershipEventType.ownershipTransferred,
    ]);
    expect(history.first.actorUserId, 'ada');
    expect(history.first.actorEmail, 'ada@example.com');
    expect(history[5].previousRole, TeamRoles.member);
    expect(history[5].at, s.backend.now);
  });

  test('history: revoke, leave and removal are recorded', () async {
    final s = await _staffedTeam();
    final invitation = await s.ada.invite(
      s.team.id,
      email: 'z@example.com',
      role: 'member',
    );
    await s.ada.revokeInvitation(invitation.id);
    await s.ada.removeMember(s.team.id, userId: 'linus');
    await s.grace.leaveTeam(s.team.id);

    final types = (await s.ada.history(s.team.id)).map((e) => e.type);

    expect(
      types,
      containsAllInOrder([
        MembershipEventType.revoked,
        MembershipEventType.removed,
        MembershipEventType.left,
      ]),
    );
  });

  test('history: outlives the membership it describes', () async {
    final s = await _staffedTeam();
    await s.ada.removeMember(s.team.id, userId: 'linus');

    final history = await s.ada.history(s.team.id);

    final accepted = history.where(
      (e) =>
          e.type == MembershipEventType.accepted && e.subjectUserId == 'linus',
    );
    expect(accepted, hasLength(1));
    expect(accepted.single.subjectEmail, 'linus@example.com');
    expect(
      history.last,
      isA<MembershipEvent>()
          .having((e) => e.type, 'type', MembershipEventType.removed)
          .having((e) => e.subjectUserId, 'subject', 'linus')
          .having((e) => e.actorUserId, 'actor', 'ada'),
    );
    expect(await s.ada.listMembers(s.team.id), hasLength(_twoMembers));
  });

  test('a signed-out service throws TeamUnauthenticatedError', () {
    final service = FakeTeamBackend().serviceForSession(() async => null);

    expect(service.listTeams, throwsA(isA<TeamUnauthenticatedError>()));
  });

  group('account deletion support', () {
    test('ownedTeams lists exactly the teams the user owns', () async {
      final w = await _staffedTeam();
      final second = await w.grace.createTeam('Grace Co');

      expect(
        (await w.backend.engine.ownedTeams('ada')).map((t) => t.id),
        <String>[w.team.id],
      );
      expect(
        (await w.backend.engine.ownedTeams('grace')).map((t) => t.id),
        <String>[second.id],
      );
      expect(await w.backend.engine.ownedTeams('linus'), isEmpty);
    });

    test('forgetUser drops memberships but keeps the history', () async {
      final w = await _staffedTeam();
      final before = (await w.ada.history(w.team.id)).length;

      await w.backend.forgetUser('linus');

      expect((await w.ada.listMembers(w.team.id)).map((m) => m.userId), [
        'ada',
        'grace',
      ]);
      final events = await w.ada.history(w.team.id);
      expect(events, hasLength(before));
      expect(events.where((e) => e.subjectUserId == 'linus'), isNotEmpty);
    });
  });

  group('email retention', () {
    test('replaces snapshots older than the period, keeps the rest', () async {
      final w = await _staffedTeam();
      w.backend.advance(const Duration(days: 400));
      await w.ada.changeRole(w.team.id, userId: 'linus', role: TeamRoles.admin);
      final old = (await w.ada.history(w.team.id)).length - 1;

      final changed = await w.backend.engine.redactEmailsOlderThan(
        const Duration(days: 365),
      );

      expect(changed, old);
      final events = await w.ada.history(w.team.id);
      expect(
        events.take(old).expand((e) => [e.actorEmail, e.subjectEmail]),
        everyElement(anyOf(isNull, MembershipEvent.formerMember)),
      );
      expect(events.last.actorEmail, 'ada@example.com');
      expect(events.first.actorUserId, 'ada');
    });

    test('is idempotent', () async {
      final w = await _staffedTeam();
      w.backend.advance(const Duration(days: 400));
      const year = Duration(days: 365);

      expect(await w.backend.engine.redactEmailsOlderThan(year), isPositive);
      expect(await w.backend.engine.redactEmailsOlderThan(year), 0);
    });

    test('changes nothing inside the period', () async {
      final w = await _staffedTeam();
      w.backend.advance(const Duration(days: 30));

      expect(
        await w.backend.engine.redactEmailsOlderThan(const Duration(days: 365)),
        0,
      );
    });
  });
}
