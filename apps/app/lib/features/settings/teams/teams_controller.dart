import 'dart:async';

import 'package:app/app/active_team_service.dart';
import 'package:app/app/router.dart';
import 'package:app/features/settings/teams/team_calls.dart';
import 'package:app/features/settings/teams/teams_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

/// Drives `TeamsView`: lists the user's teams and their pending invitations,
/// creates a team, accepts an invitation and switches the active team.
///
/// Navigates only through the injected [NavigationService], per the MVC
/// controller rule enforced by `core/architecture/mvc_lints`. A [TeamError]
/// from any call becomes [TeamsModel.failed], never an exception into the
/// view; the screen's copy is the same whatever the cause, because a
/// non-member's "not found" and a member's "not allowed" must not be told
/// apart to the user either.
class TeamsController extends ViewController<TeamsModel>
    with TeamCalls<TeamsModel> {
  /// Creates the controller.
  TeamsController(this._navigation, this._teams, this._active)
    : super(const TeamsModel());

  final NavigationService _navigation;
  final TeamService _teams;
  final ActiveTeamService _active;

  /// The new team name field's controller — owned here so it survives the
  /// view's rebuilds.
  final TextEditingController nameController = TextEditingController();

  @override
  void init() {
    unawaited(_load());
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  /// Creates a team named by [nameController] (the user becomes its owner)
  /// and makes it the active one.
  Future<void> createTeam() async {
    final name = nameController.text.trim();
    if (name.isEmpty || value.busy) return;
    await runTeamCall(() async {
      final team = await _teams.createTeam(name);
      await _active.switchTo(team.id);
      nameController.clear();
    });
  }

  /// Makes [teamId] the active team.
  Future<void> switchTo(String teamId) =>
      runTeamCall(() => _active.switchTo(teamId));

  /// Accepts the invitation [invitationId] and makes its team active.
  Future<void> acceptInvitation(String invitationId) => runTeamCall(() async {
    final membership = await _teams.acceptInvitation(invitationId);
    await _active.switchTo(membership.teamId);
  });

  /// Opens the active team's members screen.
  void openMembers() =>
      unawaited(_navigation.push(const MembersRoute().location));

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
      final invitations = await _teams.listMyInvitations();
      final stored = await _active.activeTeamId();
      // A stored ID only counts while the user still belongs to that team;
      // otherwise fall back to their first team.
      final active = teams.any((t) => t.id == stored)
          ? stored
          : (teams.isEmpty ? null : teams.first.id);
      if (active != null && active != stored) await _active.switchTo(active);
      value = TeamsModel(
        teams: teams,
        invitations: invitations,
        activeTeamId: active,
        loading: false,
      );
    } on TeamError {
      value = value.copyWith(loading: false, busy: false, failed: true);
    }
  }
}
