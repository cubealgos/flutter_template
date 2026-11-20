import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/settings/settings_hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import 'settings_hub_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<NavigationService>()])
void main() {
  group('SettingsHubController', () {
    test('showPaywall mirrors AppConfig.paywall', () {
      final on = SettingsHubController(
        MockNavigationService(),
        const AppConfig(paywall: true),
      );
      final off = SettingsHubController(
        MockNavigationService(),
        const AppConfig(),
      );

      expect(on.model.showPaywall, isTrue);
      expect(off.model.showPaywall, isFalse);
    });

    test('each open* method pushes its route', () {
      final navigation = MockNavigationService();
      SettingsHubController(navigation, const AppConfig(paywall: true))
        ..openLegal()
        ..openPrivacy()
        ..openAccount()
        ..openTeams()
        ..openPaywall();

      verify(navigation.push(const LegalHubRoute().location)).called(1);
      verify(navigation.push(const PrivacySettingsRoute().location)).called(1);
      verify(navigation.push(const AccountSettingsRoute().location)).called(1);
      verify(navigation.push(const TeamsRoute().location)).called(1);
      verify(navigation.push(const PaywallRoute().location)).called(1);
    });
  });
}
