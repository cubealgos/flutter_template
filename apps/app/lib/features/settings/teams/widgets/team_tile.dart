import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:teams/teams.dart';
import 'package:ui/ui.dart';

/// One team of the user: its name, and either an "Active" chip with a
/// "Members" button (the active team) or a "Switch" button.
class TeamTile extends StatelessWidget {
  /// Creates the tile.
  const TeamTile({
    required this.team,
    required this.active,
    required this.onSwitch,
    required this.onOpenMembers,
    super.key,
  });

  /// The team shown.
  final Team team;

  /// Whether it is the active team.
  final bool active;

  /// Called when "Switch" is pressed.
  final VoidCallback onSwitch;

  /// Called when "Members" is pressed.
  final VoidCallback onOpenMembers;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: team.name,
      subtitle: active ? t.settings.teams.activeChip : null,
      trailing: active
          ? AppButton(
              semanticLabel: '${t.settings.teams.membersButton} ${team.name}',
              onPressed: onOpenMembers,
              variant: AppButtonVariant.secondary,
              child: Text(t.settings.teams.membersButton),
            )
          : AppButton(
              semanticLabel: '${t.settings.teams.switchButton} ${team.name}',
              onPressed: onSwitch,
              variant: AppButtonVariant.secondary,
              child: Text(t.settings.teams.switchButton),
            ),
    );
  }
}
