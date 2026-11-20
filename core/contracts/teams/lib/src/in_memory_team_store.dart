import 'package:teams/src/invitation.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/membership_event.dart';
import 'package:teams/src/team.dart';
import 'package:teams/src/team_store.dart';

/// A [TeamStore] held in memory, for `FakeTeamBackend` and engine tests.
class InMemoryTeamStore implements TeamStore {
  final Map<String, Team> _teams = <String, Team>{};
  final Map<String, Membership> _memberships = <String, Membership>{};
  final Map<String, Invitation> _invitations = <String, Invitation>{};
  final List<MembershipEvent> _events = <MembershipEvent>[];

  String _key(String teamId, String userId) => '$teamId|$userId';

  @override
  Future<void> saveTeam(Team team) async => _teams[team.id] = team;

  @override
  Future<Team?> findTeam(String teamId) async => _teams[teamId];

  @override
  Future<void> saveMembership(Membership membership) async =>
      _memberships[_key(membership.teamId, membership.userId)] = membership;

  @override
  Future<void> deleteMembership(String teamId, String userId) async =>
      _memberships.remove(_key(teamId, userId));

  @override
  Future<List<Membership>> membershipsOfTeam(String teamId) async =>
      _memberships.values.where((m) => m.teamId == teamId).toList();

  @override
  Future<List<Membership>> membershipsOfUser(String userId) async =>
      _memberships.values.where((m) => m.userId == userId).toList();

  @override
  Future<void> saveInvitation(Invitation invitation) async =>
      _invitations[invitation.id] = invitation;

  @override
  Future<Invitation?> findInvitation(String invitationId) async =>
      _invitations[invitationId];

  @override
  Future<List<Invitation>> invitationsOfTeam(String teamId) async =>
      _invitations.values.where((i) => i.teamId == teamId).toList();

  @override
  Future<List<Invitation>> invitationsForEmail(String email) async =>
      _invitations.values.where((i) => i.email == email).toList();

  @override
  Future<void> appendEvent(MembershipEvent event) async => _events.add(event);

  @override
  Future<List<MembershipEvent>> eventsOfTeam(String teamId) async =>
      _events.where((e) => e.teamId == teamId).toList();

  @override
  Future<int> redactEventEmails({
    required DateTime before,
    required String marker,
  }) async {
    var changed = 0;
    for (var i = 0; i < _events.length; i++) {
      final event = _events[i];
      if (!event.at.isBefore(before)) continue;
      final redacted = event.withEmailsReplacedBy(marker);
      if (redacted.actorEmail == event.actorEmail &&
          redacted.subjectEmail == event.subjectEmail) {
        continue;
      }
      _events[i] = redacted;
      changed++;
    }

    return changed;
  }
}
