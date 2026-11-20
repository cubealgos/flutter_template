import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/bootstrap/bootstrap_controller.dart';
import 'package:app/features/bootstrap/bootstrap_status.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import '../../support/settle.dart';
import 'bootstrap_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[
  MockSpec<NavigationService>(),
  MockSpec<LauncherService>(),
])
void main() {
  group('BootstrapController', () {
    test('navigates to sign-in when the version is allowed and there is '
        'no session to restore', () async {
      final navigation = MockNavigationService();
      BootstrapController(
        navigation,
        MockLauncherService(),
        FakeVersionPolicy(),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      ).init();

      await settle();

      verify(navigation.go(const SignInRoute().location)).called(1);
    });

    test('shows the blocked state instead of navigating when the version '
        'check blocks', () async {
      final navigation = MockNavigationService();
      final controller = BootstrapController(
        navigation,
        MockLauncherService(),
        FakeVersionPolicy(
          result: VersionCheckResult(
            blocked: true,
            updateUrl: Uri.parse('https://example.com/update'),
            message: 'too old',
          ),
        ),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      )..init();

      await settle();

      expect(controller.model.status, BootstrapStatus.blocked);
      expect(
        controller.model.updateUrl,
        Uri.parse('https://example.com/update'),
      );
      verifyNever(navigation.go(any));
    });
  });

  group('BootstrapController session restore', () {
    test('navigates onward to onboarding after restoring a session', () async {
      final navigation = MockNavigationService();
      const session = AuthSession(userId: 'u1', email: 'a@b.c');
      BootstrapController(
        navigation,
        MockLauncherService(),
        FakeVersionPolicy(),
        FakeAuthService(persistedSession: session),
        const AppConfig(),
        FakeUserPreferences(),
      ).init();

      await settle();

      verify(navigation.go(const OnboardingRoute().location)).called(1);
    });

    test('openUpdateLink opens the blocked-state update URL', () async {
      final launcher = MockLauncherService();
      final url = Uri.parse('https://example.com/update');
      final controller = BootstrapController(
        MockNavigationService(),
        launcher,
        FakeVersionPolicy(
          result: VersionCheckResult(blocked: true, updateUrl: url),
        ),
        FakeAuthService(),
        const AppConfig(),
        FakeUserPreferences(),
      )..init();
      await settle();

      await controller.openUpdateLink();

      verify(launcher.openUrl(url, external: true)).called(1);
    });
  });
}
