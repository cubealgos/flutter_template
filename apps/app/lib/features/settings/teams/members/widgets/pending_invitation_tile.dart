import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:teams/teams.dart';
import 'package:ui/ui.dart';

/// One invitation still waiting for an answer, with a "Revoke" button.
class PendingInvitationTile extends StatelessWidget {
  /// Creates the tile.
  const PendingInvitationTile({
    required this.invitation,
    required this.onRevoke,
    super.key,
  });

  /// The invitation shown.
  final Invitation invitation;

  /// Called when "Revoke" is pressed.
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    // The calendar date in the viewer's time zone, as yyyy-mm-dd.
    final date = invitation.expiresAt
        .toLocal()
        .toIso8601String()
        .split('T')
        .first;

    return AppListTile(
      title: invitation.email,
      subtitle: t.settings.teams.members.pendingExpires(date: date),
      trailing: AppButton(
        semanticLabel:
            '${t.settings.teams.members.revokeButton} ${invitation.email}',
        onPressed: onRevoke,
        variant: AppButtonVariant.secondary,
        child: Text(t.settings.teams.members.revokeButton),
      ),
    );
  }
}
