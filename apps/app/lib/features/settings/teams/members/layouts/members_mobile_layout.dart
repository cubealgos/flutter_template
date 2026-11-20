import 'package:app/features/settings/teams/members/members_model.dart';
import 'package:app/features/settings/teams/members/widgets/member_tile.dart';
import 'package:app/features/settings/teams/members/widgets/members_manage_section.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// Settings → Teams → Members: the active team's members, and for its owner
/// and admins the invite form and pending invitations.
class MembersMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const MembersMobileLayout({
    required this.model,
    required this.emailController,
    required this.onBack,
    required this.onInvite,
    required this.onRevoke,
    required this.onLeave,
    super.key,
  });

  /// The state to render.
  final MembersModel model;

  /// The invite email field's text controller.
  final TextEditingController emailController;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called when "Send invitation" is pressed.
  final VoidCallback onInvite;

  /// Called with an invitation's ID when its "Revoke" button is pressed.
  final ValueChanged<String> onRevoke;

  /// Called when "Leave team" is pressed.
  final VoidCallback onLeave;

  List<Widget> _content() {
    if (model.loading) {
      return const <Widget>[Center(child: AppLoadingIndicator())];
    }
    if (model.team == null) {
      return <Widget>[
        StyledText(t.settings.teams.members.noActiveTeam, style: bodyStyle()),
      ];
    }

    return <Widget>[
      for (final member in model.members) MemberTile(member: member),
      if (model.canManage)
        MembersManageSection(
          pendingInvitations: model.pendingInvitations,
          emailController: emailController,
          busy: model.busy,
          onInvite: onInvite,
          onRevoke: onRevoke,
        ),
      if (model.canLeave) ...<Widget>[
        const AppGap.v8(),
        const AppDivider(),
        const AppGap.v8(),
        AppFullWidthButton(
          child: AppButton(
            semanticLabel: t.settings.teams.members.leaveButton,
            onPressed: onLeave,
            variant: AppButtonVariant.destructiveOutlined,
            child: Text(t.settings.teams.members.leaveButton),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: model.team?.name ?? t.settings.teams.members.title,
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
          ..._content(),
        ],
      ),
    );
  }
}
