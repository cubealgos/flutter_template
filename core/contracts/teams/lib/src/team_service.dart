import 'package:teams/src/invitation.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/membership_event.dart';
import 'package:teams/src/team.dart';

/// Teams for the signed-in user: create, invite, accept, change roles,
/// remove, leave, transfer ownership, read the history.
///
/// Every rule lives in `TeamEngine`, the one implementation both
/// `FakeTeamService` and the Appwrite backend run, so the fake can't drift
/// from the real thing. **Exactly one owner, always**: the creator owns a
/// team until they `transferOwnership`; nobody can be given or left the
/// `TeamRoles.owner` role any other way. Every method throws a `TeamError`.
///
/// A team's rows are protected separately, by `DocumentRepository`'s
/// `TeamScope` — membership here is what that scope's visibility follows.
abstract class TeamService {
  /// Creates a team named [name]; the caller becomes its owner.
  Future<Team> createTeam(String name);

  /// The teams the caller is an active member of.
  Future<List<Team>> listTeams();

  /// The members of [teamId]. Any member may list them.
  Future<List<Membership>> listMembers(String teamId);

  /// Invites [email] to [teamId] as [role] (a non-owner role). Owner and
  /// admins only; an admin can't invite an admin.
  Future<Invitation> invite(
    String teamId, {
    required String email,
    required String role,
  });

  /// The invitations of [teamId], any status. Owner and admins only.
  Future<List<Invitation>> listInvitations(String teamId);

  /// The pending invitations addressed to the caller's own email.
  Future<List<Invitation>> listMyInvitations();

  /// Accepts [invitationId] (addressed to the caller's email) and joins.
  Future<Membership> acceptInvitation(String invitationId);

  /// Withdraws a pending invitation. Owner and admins only.
  Future<void> revokeInvitation(String invitationId);

  /// Removes [userId] from [teamId]. The owner can't be removed; an admin
  /// can remove only non-admin members.
  Future<void> removeMember(String teamId, {required String userId});

  /// The caller leaves [teamId]. The owner can't leave without first
  /// transferring ownership.
  Future<void> leaveTeam(String teamId);

  /// Changes [userId]'s role in [teamId] to [role] (never the owner role,
  /// and the owner's own role can't be changed here).
  Future<Membership> changeRole(
    String teamId, {
    required String userId,
    required String role,
  });

  /// Makes [toUserId] the owner of [teamId] and the caller an admin. Owner
  /// only; [toUserId] must already be a member.
  Future<void> transferOwnership(String teamId, {required String toUserId});

  /// The team's membership history, oldest first. Owner and admins only.
  /// Entries outlive the memberships they describe.
  Future<List<MembershipEvent>> history(String teamId);
}
