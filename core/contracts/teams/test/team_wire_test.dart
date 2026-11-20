import 'package:teams/teams.dart';
import 'package:test/test.dart';

const int httpNotFound = 404;

void main() {
  test('a membership keeps its backend ID across the wire, or none', () {
    final withId = Membership(
      teamId: 't',
      userId: 'u',
      email: 'u@example.com',
      role: TeamRoles.member,
      joinedAt: DateTime.utc(2026),
      membershipId: 'native-1',
    );

    final decoded = TeamWire.decodeMembership(
      TeamWire.encodeMembership(withId),
    );

    expect(decoded.membershipId, 'native-1');
    expect(decoded.withRole(TeamRoles.admin).membershipId, 'native-1');
    final without = Membership(
      teamId: 't',
      userId: 'u',
      email: 'u@example.com',
      role: TeamRoles.member,
      joinedAt: DateTime.utc(2026),
    );
    expect(
      TeamWire.decodeMembership(
        TeamWire.encodeMembership(without),
      ).membershipId,
      isNull,
    );
  });

  test('every model survives an encode/decode round trip', () async {
    final backend = FakeTeamBackend();
    const ada = TeamActor(userId: 'ada', email: 'ada@example.com');
    final service = backend.serviceFor(ada);
    final team = await service.createTeam('Acme');
    final invitation = await service.invite(
      team.id,
      email: 'g@example.com',
      role: TeamRoles.admin,
    );
    final member = (await service.listMembers(team.id)).single;
    final event = (await service.history(team.id)).first;

    final decodedTeam = TeamWire.decodeTeam(TeamWire.encodeTeam(team));
    expect(decodedTeam.id, team.id);
    expect(decodedTeam.name, 'Acme');
    final decodedMember = TeamWire.decodeMembership(
      TeamWire.encodeMembership(member),
    );
    expect(decodedMember.userId, 'ada');
    expect(decodedMember.role, TeamRoles.owner);
    expect(decodedMember.joinedAt, member.joinedAt);
    final decodedInvitation = TeamWire.decodeInvitation(
      TeamWire.encodeInvitation(invitation),
    );
    expect(decodedInvitation.id, invitation.id);
    expect(decodedInvitation.expiresAt, invitation.expiresAt);
    expect(decodedInvitation.status, InvitationStatus.pending);
    final decodedEvent = TeamWire.decodeEvent(TeamWire.encodeEvent(event));
    expect(decodedEvent.type, event.type);
    expect(decodedEvent.at, event.at);
    expect(decodedEvent.subjectUserId, 'ada');
    expect(decodedEvent.previousRole, isNull);
  });

  test('every error maps to a code and back to the same type', () {
    const errors = <TeamError>[
      TeamNotFoundError('m'),
      TeamUnauthenticatedError('m'),
      TeamPermissionError('m'),
      TeamInvariantError('m'),
      TeamInvitationError('m'),
    ];
    for (final error in errors) {
      final decoded = TeamWire.errorFrom(TeamWire.codeFor(error), 'm');
      expect(decoded.runtimeType, error.runtimeType);
    }
    expect(TeamWire.errorFrom('whatever', 'm'), isA<TeamUnknownError>());
    expect(TeamWire.statusFor(const TeamNotFoundError('m')), httpNotFound);
  });
}
