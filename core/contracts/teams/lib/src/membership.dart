/// An active member of a team. An invitation not yet accepted is an
/// `Invitation`, never a [Membership].
class Membership {
  /// Creates a membership.
  const Membership({
    required this.teamId,
    required this.userId,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.membershipId,
  });

  /// The team this membership belongs to.
  final String teamId;

  /// The member's user ID.
  final String userId;

  /// The member's email when they joined.
  final String email;

  /// The member's role — see `TeamRoles`.
  final String role;

  /// When the member joined (the team was created, for its owner).
  final DateTime joinedAt;

  /// The backend's own ID for this membership, when it has one (Appwrite's
  /// membership `$id`); null in the fake. Opaque, and not secret: any member
  /// may list memberships. Lets a live test aim a raw Teams SDK call at the
  /// real membership.
  final String? membershipId;

  /// A copy with [role] replaced.
  Membership withRole(String role) => Membership(
    teamId: teamId,
    userId: userId,
    email: email,
    role: role,
    joinedAt: joinedAt,
    membershipId: membershipId,
  );

  @override
  String toString() => 'Membership(team: $teamId, user: $userId, role: $role)';
}
