/// The Appwrite team role a membership holds for the contract's owner.
///
/// Appwrite lets a team member whose native role is literally `owner` invite,
/// re-role and remove members through the client SDK, bypassing
/// `backend/appwrite/functions/team_admin`, which is what keeps a team to
/// exactly one owner. So nobody is ever given that native role: the
/// contract's owner holds this one instead, and every membership change goes
/// through the Function (which uses an API key, not a member's rights).
const String nativeOwnerRole = 'tenant_owner';

/// The Appwrite team role for the contract role [role] (`TeamRoles` in
/// `core/contracts/teams`): the owner role is [nativeOwnerRole], every other
/// role is its own name.
///
/// Used both when the Function writes a membership's roles and when the
/// adapter builds a row's `Role.team(teamId, role)` permission, so the two
/// can never disagree.
String nativeTeamRole(String role) => role == 'owner' ? nativeOwnerRole : role;
