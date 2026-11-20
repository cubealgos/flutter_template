import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:teams/teams.dart';
import 'package:ui/ui.dart';

/// One member of the team: their email and role.
class MemberTile extends StatelessWidget {
  /// Creates the tile.
  const MemberTile({required this.member, super.key});

  /// The member shown.
  final Membership member;

  @override
  Widget build(BuildContext context) {
    return AppListTile(title: member.email, subtitle: _roleLabel(member.role));
  }
}

/// The localized name of [role]; an app-defined role is shown as is.
String _roleLabel(String role) => switch (role) {
  TeamRoles.owner => t.settings.teams.members.roleOwner,
  TeamRoles.admin => t.settings.teams.members.roleAdmin,
  TeamRoles.member => t.settings.teams.members.roleMember,
  _ => role,
};
