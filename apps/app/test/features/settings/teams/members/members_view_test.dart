import 'dart:io';

import 'package:app/app/active_team_service.dart';
import 'package:app/app/di.dart';
import 'package:app/features/settings/teams/members/members_view.dart';
import 'package:auth/auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import '../../../../support/screen_harness.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, MembersView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(MembersView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows an owner their team in ${brightness.name}', (
      tester,
    ) async {
      // The DI graph's Appwrite `Client` (built on the fake backend too)
      // asks `path_provider` for a cookie path; see `pumpScreen`.
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => Directory.systemTemp.path,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      configureDependencies();
      final auth = getIt<AuthService>();
      final request = await auth.requestEmailCode('ada@example.com');
      await auth.verifyEmailCode(request, FakeAuthService.fixedEmailCode);
      final teams = getIt<TeamService>();
      final team = await teams.createTeam('Acme');
      await teams.invite(
        team.id,
        email: 'grace@example.com',
        role: TeamRoles.member,
      );
      await getIt<ActiveTeamService>().switchTo(team.id);

      await pumpScreen(tester, MembersView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('grace@example.com'), findsOneWidget);
      expect(find.text('Send invitation'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
