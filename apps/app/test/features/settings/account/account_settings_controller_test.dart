import 'package:app/app/router.dart';
import 'package:app/features/settings/account/account_delete_error.dart';
import 'package:app/features/settings/account/account_settings_controller.dart';
import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

import '../../../support/settle.dart';
import '../../../support/team_test_world.dart';
import 'account_settings_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[
  MockSpec<NavigationService>(),
  MockSpec<DialogService>(),
])
const int _ownedCount = 2;

MockDialogService confirming() {
  final dialogService = MockDialogService();
  when(dialogService.show<bool>(any)).thenAnswer((_) async => true);

  return dialogService;
}

void main() {
  group('AccountSettingsController identities', () {
    test('loads linked identities on init', () async {
      final auth = FakeAuthService();
      await auth.signInWithOAuth(OAuthProvider.google);
      final controller = AccountSettingsController(
        MockNavigationService(),
        auth,
        MockDialogService(),
      )..init();

      await settle();

      expect(controller.model.loading, isFalse);
      expect(controller.model.identities, hasLength(1));
      expect(controller.model.identities.single.provider, 'google');
    });

    test('disconnect unlinks the identity and refreshes the list', () async {
      final auth = FakeAuthService();
      await auth.signInWithOAuth(OAuthProvider.google);
      final controller = AccountSettingsController(
        MockNavigationService(),
        auth,
        MockDialogService(),
      )..init();
      await settle();
      final identityId = controller.model.identities.single.id;

      await controller.disconnect(identityId);

      expect(controller.model.identities, isEmpty);
    });
  });

  group('AccountSettingsController delete account', () {
    test('deletes the account and returns to sign-in when confirmed', () async {
      final navigation = MockNavigationService();
      final dialogService = MockDialogService();
      when(dialogService.show<bool>(any)).thenAnswer((_) async => true);
      final auth = FakeAuthService();
      await auth.signInWithPasskey();
      final controller = AccountSettingsController(
        navigation,
        auth,
        dialogService,
      );

      await controller.confirmAndDeleteAccount();

      expect(auth.currentSession, isNull);
      verify(navigation.go(const SignInRoute().location)).called(1);
    });

    test('does nothing when the confirm dialog is declined — no support '
        'ticket step, but no deletion either', () async {
      final navigation = MockNavigationService();
      final dialogService = MockDialogService();
      when(dialogService.show<bool>(any)).thenAnswer((_) async => false);
      final auth = FakeAuthService();
      await auth.signInWithPasskey();
      final controller = AccountSettingsController(
        navigation,
        auth,
        dialogService,
      );

      await controller.confirmAndDeleteAccount();

      expect(auth.currentSession, isNotNull);
      verifyNever(navigation.go(any));
    });
  });

  group('with teams', () {
    test('an owner is refused: the screen stays, naming the teams, and '
        'the account survives', () async {
      final world = TeamTestWorld();
      await world.ada.auth.restoreSession();
      await world.ada.teams.createTeam('Acme');
      await world.ada.teams.createTeam('Side Project');
      final navigation = MockNavigationService();
      final controller = AccountSettingsController(
        navigation,
        world.ada.auth,
        confirming(),
      );

      await controller.confirmAndDeleteAccount();

      expect(controller.model.deleteError, AccountDeleteError.ownsTeams);
      expect(controller.model.ownedTeamNames, <String>['Acme', 'Side Project']);
      expect(world.ada.auth.currentSession, isNotNull);
      verifyNever(navigation.go(any));
      expect(await world.ada.teams.listTeams(), hasLength(_ownedCount));
    });
  });

  group('with teams, as a member', () {
    test('a member deletes fine; the team keeps its owner and its '
        'history', () async {
      final world = TeamTestWorld();
      await world.ada.auth.restoreSession();
      await world.grace.auth.restoreSession();
      final team = await world.ada.teams.createTeam('Acme');
      final invitation = await world.ada.teams.invite(
        team.id,
        email: world.grace.email,
        role: TeamRoles.member,
      );
      await world.grace.teams.acceptInvitation(invitation.id);
      final eventsBefore = (await world.ada.teams.history(team.id)).length;
      final navigation = MockNavigationService();
      final controller = AccountSettingsController(
        navigation,
        world.grace.auth,
        confirming(),
      );

      await controller.confirmAndDeleteAccount();

      expect(controller.model.deleteError, isNull);
      expect(world.grace.auth.currentSession, isNull);
      verify(navigation.go(const SignInRoute().location)).called(1);
      final members = await world.ada.teams.listMembers(team.id);
      expect(members.map((m) => m.userId), <String>[world.ada.userId]);
      expect(await world.ada.teams.history(team.id), hasLength(eventsBefore));
    });
  });
}
