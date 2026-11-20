import 'package:app/features/settings/teams/teams_model.dart';
import 'package:app/features/settings/teams/widgets/create_team_form.dart';
import 'package:app/features/settings/teams/widgets/invitation_tile.dart';
import 'package:app/features/settings/teams/widgets/team_tile.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// Settings → Teams: the user's teams (switch the active one), the
/// invitations waiting for them, and a form to create a team.
class TeamsMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const TeamsMobileLayout({
    required this.model,
    required this.nameController,
    required this.onBack,
    required this.onCreate,
    required this.onSwitch,
    required this.onAccept,
    required this.onOpenMembers,
    super.key,
  });

  /// The state to render.
  final TeamsModel model;

  /// The new team name field's text controller.
  final TextEditingController nameController;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called when "Create team" is pressed.
  final VoidCallback onCreate;

  /// Called with a team's ID when its "Switch" button is pressed.
  final ValueChanged<String> onSwitch;

  /// Called with an invitation's ID when its "Accept" button is pressed.
  final ValueChanged<String> onAccept;

  /// Called when the active team's "Members" button is pressed.
  final VoidCallback onOpenMembers;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: t.settings.teams.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (model.failed)
            StyledText(
              t.settings.teams.failed,
              style: bodyStyle().color(colorDanger()),
            ),
          if (model.loading)
            const Center(child: AppLoadingIndicator())
          else if (model.teams.isEmpty)
            StyledText(t.settings.teams.noTeams, style: bodyStyle())
          else
            for (final team in model.teams)
              TeamTile(
                team: team,
                active: team.id == model.activeTeamId,
                onSwitch: () => onSwitch(team.id),
                onOpenMembers: onOpenMembers,
              ),
          if (model.invitations.isNotEmpty) ...<Widget>[
            const AppGap.v8(),
            StyledText(t.settings.teams.invitationsTitle, style: h2Style()),
            const AppGap.v3(),
            for (final invitation in model.invitations)
              InvitationTile(
                invitation: invitation,
                onAccept: () => onAccept(invitation.id),
              ),
          ],
          const AppGap.v8(),
          const AppDivider(),
          const AppGap.v8(),
          StyledText(t.settings.teams.createTitle, style: h2Style()),
          const AppGap.v3(),
          CreateTeamForm(
            nameController: nameController,
            busy: model.busy,
            onCreate: onCreate,
          ),
        ],
      ),
    );
  }
}
