import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:teams/teams.dart';

/// The native Appwrite team roles a membership with contract [role] holds:
/// `TeamRoles.implied`, with the owner role renamed so nobody is ever a
/// native Appwrite `owner` (see `nativeOwnerRole`).
List<String> nativeRolesFor(String role) =>
    TeamRoles.implied(role).map(nativeTeamRole).toList();

/// The contract role a native role list stands for: the inverse of
/// [nativeRolesFor].
String contractRoleOf(List<String> nativeRoles) {
  if (nativeRoles.contains(nativeOwnerRole)) return TeamRoles.owner;
  if (nativeRoles.contains(TeamRoles.admin)) return TeamRoles.admin;

  return nativeRoles.firstWhere(
    (r) => r != TeamRoles.member,
    orElse: () => TeamRoles.member,
  );
}
