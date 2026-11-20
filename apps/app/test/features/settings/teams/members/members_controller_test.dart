import 'package:app/features/settings/teams/members/members_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import '../../../../support/recording_navigation_service.dart';
import '../../../../support/settle.dart';
import '../../../../support/team_test_world.dart';

MembersController _controllerFor(
  TeamTestUser user, {
  RecordingNavigationService? navigation,
}) => MembersController(
  navigation ?? RecordingNavigationService(),
  user.teams,
  user.active,
  user.auth,
)..init();

/// Ada owns "Acme" (active for both) and Grace is a plain member of it.
Future<(TeamTestWorld, Team)> _staffedWorld() async {
  final world = TeamTestWorld();
  final team = await world.ada.teams.createTeam('Acme');
  final invitation = await world.ada.teams.invite(
    team.id,
    email: world.grace.email,
    role: TeamRoles.member,
  );
  await world.grace.teams.acceptInvitation(invitation.id);
  await world.ada.active.switchTo(team.id);
  await world.grace.active.switchTo(team.id);

  return (world, team);
}

const int _ownerAndMember = 2;

void main() {
  test('without an active team the screen has no team', () async {
    final world = TeamTestWorld();
    final controller = _controllerFor(world.ada);

    await settle();

    expect(controller.model.loading, isFalse);
    expect(controller.model.team, isNull);
  });

  test('the owner sees members and may manage', () async {
    final (world, _) = await _staffedWorld();
    // `FakeAuthService.currentSession` needs a restore to be populated.
    await world.ada.auth.restoreSession();
    final controller = _controllerFor(world.ada);

    await settle();

    expect(controller.model.team?.name, 'Acme');
    expect(controller.model.members, hasLength(_ownerAndMember));
    expect(controller.model.myRole, TeamRoles.owner);
    expect(controller.model.canManage, isTrue);
    expect(controller.model.canLeave, isFalse);
  });

  test('inviting adds a pending invitation; revoking removes it', () async {
    final (world, _) = await _staffedWorld();
    await world.ada.auth.restoreSession();
    final controller = _controllerFor(world.ada);
    await settle();

    controller.emailController.text = 'new@example.com';
    await controller.invite();

    final pending = controller.model.pendingInvitations.single;
    expect(pending.email, 'new@example.com');
    expect(pending.role, invitedRole);
    expect(controller.emailController.text, isEmpty);

    await controller.revoke(pending.id);

    expect(controller.model.pendingInvitations, isEmpty);
  });

  test(
    'a plain member can leave but not manage, and sees no invitations',
    () async {
      final (world, _) = await _staffedWorld();
      await world.grace.auth.restoreSession();
      final navigation = RecordingNavigationService();
      final controller = _controllerFor(world.grace, navigation: navigation);
      await settle();

      expect(controller.model.canManage, isFalse);
      expect(controller.model.canLeave, isTrue);
      expect(controller.model.pendingInvitations, isEmpty);

      await controller.leave();

      expect(await world.grace.teams.listTeams(), isEmpty);
      expect(navigation.pops, 1);
    },
  );

  test('a call the engine refuses is reported as failed', () async {
    final (world, _) = await _staffedWorld();
    await world.ada.auth.restoreSession();
    final controller = _controllerFor(world.ada);
    await settle();

    // The owner can't be invited twice, nor a member re-invited.
    controller.emailController.text = world.grace.email;
    await controller.invite();

    expect(controller.model.failed, isTrue);
  });
}
