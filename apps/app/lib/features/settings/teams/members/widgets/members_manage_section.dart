import 'package:app/features/settings/teams/members/widgets/invite_form.dart';
import 'package:app/features/settings/teams/members/widgets/pending_invitation_tile.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:teams/teams.dart';
import 'package:ui/ui.dart';

/// What only the owner and admins see on the members screen: the invite
/// form and the invitations still waiting for an answer.
class MembersManageSection extends StatelessWidget {
  /// Creates the section.
  const MembersManageSection({
    required this.pendingInvitations,
    required this.emailController,
    required this.busy,
    required this.onInvite,
    required this.onRevoke,
    super.key,
  });

  /// The invitations still pending.
  final List<Invitation> pendingInvitations;

  /// The invite email field's text controller.
  final TextEditingController emailController;

  /// Whether a call is running.
  final bool busy;

  /// Called when "Send invitation" is pressed.
  final VoidCallback onInvite;

  /// Called with an invitation's ID when its "Revoke" button is pressed.
  final ValueChanged<String> onRevoke;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppGap.v8(),
        StyledText(t.settings.teams.members.inviteTitle, style: h2Style()),
        const AppGap.v3(),
        InviteForm(
          emailController: emailController,
          busy: busy,
          onInvite: onInvite,
        ),
        if (pendingInvitations.isNotEmpty) ...<Widget>[
          const AppGap.v8(),
          StyledText(t.settings.teams.members.pendingTitle, style: h2Style()),
          const AppGap.v3(),
          for (final invitation in pendingInvitations)
            PendingInvitationTile(
              invitation: invitation,
              onRevoke: () => onRevoke(invitation.id),
            ),
        ],
      ],
    );
  }
}
