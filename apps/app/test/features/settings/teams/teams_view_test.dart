import 'dart:io';

import 'package:app/app/di.dart';
import 'package:app/features/settings/teams/teams_view.dart';
import 'package:auth/auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

import '../../../support/screen_harness.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, TeamsView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(TeamsView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists a team in ${brightness.name}', (tester) async {
      // Signed in as a user who owns a team, so a tile, the chip and the
      // buttons go through the accessibility guidelines `pumpScreen`
      // asserts.
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
      await getIt<TeamService>().createTeam('Acme');
      await pumpScreen(tester, TeamsView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.text('Acme'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
