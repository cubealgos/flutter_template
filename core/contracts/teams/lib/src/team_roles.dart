/// The roles a team member can hold, and which each one implies.
///
/// A role is a plain [String], so an app can define its own (`billing`,
/// `auditor`) next to these three — see `TeamEngine.assignableRoles`. Every
/// member holds `member`; an admin also holds `admin`; the owner holds all
/// three. That implication is what lets a row scoped to `member` be read by
/// admins and the owner without listing them, and it is the same expansion
/// the Appwrite adapter writes onto a team membership.
abstract final class TeamRoles {
  /// The one member who owns the team: exactly one per team, always.
  static const String owner = 'owner';

  /// A member who can manage everyone except the owner and other admins.
  static const String admin = 'admin';

  /// Every active member.
  static const String member = 'member';

  /// The roles a membership with [role] holds: [role] itself, `member`,
  /// and for the owner also `admin`.
  static Set<String> implied(String role) => <String>{
    role,
    member,
    if (role == owner) admin,
  };
}
