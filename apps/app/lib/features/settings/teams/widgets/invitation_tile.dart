import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:teams/teams.dart';
import 'package:ui/ui.dart';

/// One pending invitation addressed to the user, with an "Accept" button.
class InvitationTile extends StatelessWidget {
  /// Creates the tile.
  const InvitationTile({
    required this.invitation,
    required this.onAccept,
    super.key,
  });

  /// The invitation shown.
  final Invitation invitation;

  /// Called when "Accept" is pressed.
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: invitation.teamName,
      subtitle: t.settings.teams.invitationRole(role: invitation.role),
      trailing: AppButton(
        semanticLabel: t.settings.teams.acceptButton,
        onPressed: onAccept,
        child: Text(t.settings.teams.acceptButton),
      ),
    );
  }
}
