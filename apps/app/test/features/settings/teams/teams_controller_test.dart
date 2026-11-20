import 'package:app/app/router.dart';
import 'package:app/features/settings/teams/teams_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import '../../../support/recording_navigation_service.dart';
import '../../../support/settle.dart';
import '../../../support/team_test_world.dart';

TeamsController _controllerFor(TeamTestUser user) =>
    TeamsController(RecordingNavigationService(), user.teams, user.active)
      ..init();

void main() {
  test('starts empty and not failed for a user with no team', () async {
    final world = TeamTestWorld();
    final controller = _controllerFor(world.ada);

    await settle();

    expect(controller.model.loading, isFalse);
    expect(controller.model.teams, isEmpty);
    expect(controller.model.activeTeamId, isNull);
    expect(controller.model.failed, isFalse);
  });

  test(
    'creating a team lists it, makes it active and clears the field',
    () async {
      final world = TeamTestWorld();
      final controller = _controllerFor(world.ada);
      await settle();

      controller.nameController.text = '  Acme ';
      await controller.createTeam();

      final team = controller.model.teams.single;
      expect(team.name, 'Acme');
      expect(controller.model.activeTeamId, team.id);
      expect(await world.ada.active.activeTeamId(), team.id);
      expect(controller.nameController.text, isEmpty);
      // The creator is the owner.
      expect(
        (await world.ada.teams.listMembers(team.id)).single.role,
        TeamRoles.owner,
      );
    },
  );

  test('a blank team name does nothing', () async {
    final world = TeamTestWorld();
    final controller = _controllerFor(world.ada);
    await settle();

    controller.nameController.text = '   ';
    await controller.createTeam();

    expect(controller.model.teams, isEmpty);
    expect(controller.model.failed, isFalse);
  });

  test(
    'an invitation shows up, can be accepted and makes the team active',
    () async {
      final world = TeamTestWorld();
      final team = await world.grace.teams.createTeam('Grace Co');
      await world.grace.teams.invite(
        team.id,
        email: world.ada.email,
        role: TeamRoles.member,
      );
      final controller = _controllerFor(world.ada);
      await settle();
      expect(controller.model.invitations.single.teamName, 'Grace Co');

      await controller.acceptInvitation(controller.model.invitations.single.id);

      expect(controller.model.invitations, isEmpty);
      expect(controller.model.teams.single.id, team.id);
      expect(controller.model.activeTeamId, team.id);
    },
  );

  test('switching the active team is remembered', () async {
    final world = TeamTestWorld();
    final first = await world.ada.teams.createTeam('One');
    final second = await world.ada.teams.createTeam('Two');
    await world.ada.active.switchTo(first.id);
    final controller = _controllerFor(world.ada);
    await settle();
    expect(controller.model.activeTeamId, first.id);

    await controller.switchTo(second.id);

    expect(controller.model.activeTeamId, second.id);
    expect(await world.ada.active.activeTeamId(), second.id);
  });

  test('a stored team the user no longer belongs to is ignored', () async {
    final world = TeamTestWorld();
    final mine = await world.ada.teams.createTeam('Mine');
    await world.ada.active.switchTo('a-team-i-was-removed-from');

    final controller = _controllerFor(world.ada);
    await settle();

    expect(controller.model.activeTeamId, mine.id);
    expect(await world.ada.active.activeTeamId(), mine.id);
  });

  test('a rejected call is reported as failed, not thrown', () async {
    final world = TeamTestWorld();
    final controller = _controllerFor(world.ada);
    await settle();

    await controller.acceptInvitation('not-an-invitation');

    expect(controller.model.failed, isTrue);
    expect(controller.model.busy, isFalse);
  });

  test('openMembers pushes the members route; goBack pops', () async {
    final world = TeamTestWorld();
    final navigation = RecordingNavigationService();
    TeamsController(navigation, world.ada.teams, world.ada.active)
      ..openMembers()
      ..goBack();

    expect(navigation.pushed, [const MembersRoute().location]);
    expect(navigation.pops, 1);
  });
}
