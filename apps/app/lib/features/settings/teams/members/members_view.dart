import 'package:app/app/active_team_service.dart';
import 'package:app/app/di.dart';
import 'package:app/features/settings/teams/members/layouts/members_mobile_layout.dart';
import 'package:app/features/settings/teams/members/members_controller.dart';
import 'package:app/features/settings/teams/members/members_model.dart';
import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

/// Settings → Teams → Members: the active team's members, with invite and
/// revoke for its owner and admins.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `MembersMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class MembersView extends ViewWidget<MembersModel, MembersController> {
  /// Creates the view.
  MembersView({super.key});

  @override
  MembersController createController() => MembersController(
    getIt<NavigationService>(),
    getIt<TeamService>(),
    getIt<ActiveTeamService>(),
    getIt<AuthService>(),
  );

  @override
  Widget build(
    BuildContext context,
    MembersController controller,
    MembersModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => MembersMobileLayout(
        model: model,
        emailController: controller.emailController,
        onBack: controller.goBack,
        onInvite: controller.invite,
        onRevoke: controller.revoke,
        onLeave: controller.leave,
      ),
    );
  }
}
