/// Who may see and change a document: set once, when it is created.
///
/// User-scoped rows ([UserScope]) belong to one person; team-scoped rows
/// ([TeamScope]) belong to an organisation, so every member of it sees the
/// same data and a removed member loses access at once. Pick by asking
/// "whose is this row?": a person's own settings and drafts are
/// [UserScope]; anything an organisation's members share is [TeamScope].
/// The root `CLAUDE.md` and `apps/app/README.md` spell the rule out.
sealed class DocumentScope {
  const DocumentScope();
}

/// The document belongs to the current user alone. The default.
final class UserScope extends DocumentScope {
  /// Scopes to the current user.
  const UserScope();
}

/// The document belongs to the team [teamId].
///
/// Which members may read it is [readRoles]; which may update and delete it
/// is [writeRoles]. A null set means "every member". Roles are
/// `package:teams`'s `TeamRoles` (an app's own as well), and a member holds
/// the roles `TeamRoles.implied` lists: the owner is an admin and a member,
/// an admin is a member. So `readRoles: {'admin'}` is an admins-only row
/// that the owner can read too.
///
/// **A creator can only scope a row to roles they hold themselves**
/// (Appwrite refuses anything else): a plain member can't create an
/// admins-only row, and only the owner can name `owner` in a set. Naming a
/// role the owner doesn't hold (an app-defined one) leaves the owner out
/// unless `owner` is listed too.
final class TeamScope extends DocumentScope {
  /// Scopes to [teamId], optionally narrowed by role.
  const TeamScope(this.teamId, {this.readRoles, this.writeRoles});

  /// The team that owns the document.
  final String teamId;

  /// The roles that may read it; null for every member.
  final Set<String>? readRoles;

  /// The roles that may update and delete it; null to mean the same as
  /// [readRoles].
  final Set<String>? writeRoles;
}
