import 'dart:async';

import 'package:app/app/active_team_service.dart';
import 'package:app/features/settings/teams/members/members_model.dart';
import 'package:app/features/settings/teams/team_calls.dart';
import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

/// The role an invitation sent from this screen grants. Promoting to admin
/// (owner only) is a `TeamService.changeRole` call a clone adds a button for.
const String invitedRole = TeamRoles.member;

/// Drives `MembersView`: the active team's members and pending invitations,
/// inviting by email, revoking an invitation and leaving the team.
///
/// Which buttons appear follows [MembersModel.canManage] and
/// [MembersModel.canLeave], but that is convenience only: the rules are
/// `TeamEngine`'s, so a call the user isn't allowed to make fails with a
/// [TeamError], shown as [MembersModel.failed].
class MembersController extends ViewController<MembersModel>
    with TeamCalls<MembersModel> {
  /// Creates the controller.
  MembersController(this._navigation, this._teams, this._active, this._auth)
    : super(const MembersModel());

  final NavigationService _navigation;
  final TeamService _teams;
  final ActiveTeamService _active;
  final AuthService _auth;

  /// The invite email field's controller — owned here so it survives the
  /// view's rebuilds.
  final TextEditingController emailController = TextEditingController();

  @override
  void init() {
    unawaited(_load());
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  /// Invites the email in [emailController] to the team as [invitedRole].
  Future<void> invite() async {
    final team = value.team;
    final email = emailController.text.trim();
    if (team == null || email.isEmpty || value.busy) return;
    await runTeamCall(() async {
      await _teams.invite(team.id, email: email, role: invitedRole);
      emailController.clear();
    });
  }

  /// Withdraws the pending invitation [invitationId].
  Future<void> revoke(String invitationId) =>
      runTeamCall(() => _teams.revokeInvitation(invitationId));

  /// Leaves the team and returns to the previous screen.
  Future<void> leave() async {
    final team = value.team;
    if (team == null) return;
    if (await attemptTeamCall(() => _teams.leaveTeam(team.id))) return goBack();
    value = value.copyWith(failed: true);
  }

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }

  @override
  void showCallState({required bool busy, required bool failed}) =>
      value = value.copyWith(busy: busy, failed: failed);

  @override
  Future<void> reload() => _load();

  Future<void> _load() async {
    try {
      final teams = await _teams.listTeams();
      final activeId = await _active.activeTeamId();
      final matching = teams.where((t) => t.id == activeId);
      if (matching.isEmpty) {
        value = const MembersModel(loading: false);

        return;
      }
      final team = matching.first;
      final members = await _teams.listMembers(team.id);
      final me = _auth.currentSession?.userId;
      final myRole = members.where((m) => m.userId == me).firstOrNull?.role;
      final manager = myRole == TeamRoles.owner || myRole == TeamRoles.admin;
      final invitations = manager
          ? (await _teams.listInvitations(
              team.id,
            )).where((i) => i.status == InvitationStatus.pending).toList()
          : const <Invitation>[];
      value = MembersModel(
        team: team,
        members: members,
        pendingInvitations: invitations,
        myRole: myRole,
        loading: false,
      );
    } on TeamError {
      value = value.copyWith(loading: false, busy: false, failed: true);
    }
  }
}
