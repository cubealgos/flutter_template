import 'package:teams/src/invitation_status.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/team_error.dart';

/// An offer to join a team, addressed to an email.
///
/// The invitee signs in with that (verified) email and accepts it from
/// `TeamService.listMyInvitations`; there is no emailed link or secret.
/// Delivering a notification email is the clone's job (see
/// `apps/app/README.md`).
class Invitation {
  /// Creates an invitation.
  const Invitation({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.createdAt,
    required this.expiresAt,
    this.status = InvitationStatus.pending,
  });

  /// The invitation's ID.
  final String id;

  /// The team it invites to.
  final String teamId;

  /// The team's name when the invitation was made, so an invitee (who is not
  /// a member yet, and can't read the team) can see where they are invited.
  final String teamName;

  /// The invitee's email, lower-cased.
  final String email;

  /// The role the invitee gets on accepting.
  final String role;

  /// The user ID of whoever invited.
  final String invitedBy;

  /// When it was created.
  final DateTime createdAt;

  /// After this instant it can no longer be accepted.
  final DateTime expiresAt;

  /// Where it stands.
  final InvitationStatus status;

  /// Whether it is still waiting for an answer.
  bool get isPending => status == InvitationStatus.pending;

  /// Whether it is pending but past [expiresAt] at [now].
  bool hasLapsedAt(DateTime now) => isPending && !now.isBefore(expiresAt);

  /// Whether it is a pending invitation of [email] (lower-cased).
  bool isPendingFor(String email) => isPending && this.email == email;

  /// Throws a [TeamInvitationError] unless it is still pending.
  void requirePending() {
    if (!isPending) {
      throw TeamInvitationError(
        'The invitation is ${status.name}, not pending.',
      );
    }
  }

  /// The membership [userId] gets by accepting this invitation at [at].
  Membership acceptedBy(String userId, DateTime at) => Membership(
    teamId: teamId,
    userId: userId,
    email: email,
    role: role,
    joinedAt: at,
  );

  /// A copy with [status] replaced.
  Invitation withStatus(InvitationStatus status) => Invitation(
    id: id,
    teamId: teamId,
    teamName: teamName,
    email: email,
    role: role,
    invitedBy: invitedBy,
    createdAt: createdAt,
    expiresAt: expiresAt,
    status: status,
  );

  @override
  String toString() =>
      'Invitation(id: $id, team: $teamId, email: $email, status: $status)';
}
