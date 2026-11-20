import 'package:teams/src/invitation.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/membership_event.dart';
import 'package:teams/src/team.dart';

/// Where `TeamEngine` keeps its state: teams, memberships, invitations and
/// the append-only history. Rules live in the engine; a store only
/// persists, so a bug here can't change who may do what.
///
/// `InMemoryTeamStore` backs the fake; `backend/appwrite/functions/
/// team_admin` implements it over Appwrite Teams (memberships) and tables
/// (invitations, events).
abstract interface class TeamStore {
  /// Creates or replaces [team].
  Future<void> saveTeam(Team team);

  /// The team with [teamId], or null.
  Future<Team?> findTeam(String teamId);

  /// Creates or replaces the membership of `membership.userId` in
  /// `membership.teamId`.
  Future<void> saveMembership(Membership membership);

  /// Removes [userId]'s membership of [teamId].
  Future<void> deleteMembership(String teamId, String userId);

  /// Every active membership of [teamId].
  Future<List<Membership>> membershipsOfTeam(String teamId);

  /// Every active membership of [userId], across teams.
  Future<List<Membership>> membershipsOfUser(String userId);

  /// Creates or replaces [invitation] (keyed by its ID).
  Future<void> saveInvitation(Invitation invitation);

  /// The invitation with [invitationId], or null.
  Future<Invitation?> findInvitation(String invitationId);

  /// Every invitation of [teamId], any status.
  Future<List<Invitation>> invitationsOfTeam(String teamId);

  /// Every invitation addressed to [email] (lower-cased), any status.
  Future<List<Invitation>> invitationsForEmail(String email);

  /// Appends [event] to its team's history.
  Future<void> appendEvent(MembershipEvent event);

  /// The history of [teamId], oldest first.
  Future<List<MembershipEvent>> eventsOfTeam(String teamId);

  /// Replaces the email snapshots (`actorEmail`, `subjectEmail`) of every
  /// event older than [before] by [marker], and returns how many events it
  /// changed. Events whose snapshots already read [marker], or that have
  /// none, are not counted, so a second call changes nothing. The one place
  /// the otherwise append-only history is edited: the retention hook (see
  /// `TeamEngine.redactEmailsOlderThan`).
  Future<int> redactEventEmails({
    required DateTime before,
    required String marker,
  });
}
