import 'package:app/app/active_team_service.dart';
import 'package:app/app/di.dart';
import 'package:app/features/settings/teams/layouts/teams_mobile_layout.dart';
import 'package:app/features/settings/teams/teams_controller.dart';
import 'package:app/features/settings/teams/teams_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

/// Settings → Teams: create a team, accept an invitation, switch the active
/// team.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `TeamsMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class TeamsView extends ViewWidget<TeamsModel, TeamsController> {
  /// Creates the view.
  TeamsView({super.key});

  @override
  TeamsController createController() => TeamsController(
    getIt<NavigationService>(),
    getIt<TeamService>(),
    getIt<ActiveTeamService>(),
  );

  @override
  Widget build(
    BuildContext context,
    TeamsController controller,
    TeamsModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => TeamsMobileLayout(
        model: model,
        nameController: controller.nameController,
        onBack: controller.goBack,
        onCreate: controller.createTeam,
        onSwitch: controller.switchTo,
        onAccept: controller.acceptInvitation,
        onOpenMembers: controller.openMembers,
      ),
    );
  }
}
