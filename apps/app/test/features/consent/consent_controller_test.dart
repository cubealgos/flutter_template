import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:app/features/consent/consent_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import 'consent_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<NavigationService>()])
void main() {
  group('ConsentController', () {
    test('accept stores true and moves on to onboarding', () async {
      final navigation = MockNavigationService();
      final preferences = FakeUserPreferences();
      final controller = ConsentController(navigation, preferences);

      await controller.accept();

      expect(
        (await preferences.getAll())[consentAcceptedPreferenceKey],
        isTrue,
      );
      verify(navigation.go(const OnboardingRoute().location)).called(1);
    });

    test('reject stores false and moves on exactly like accept — equal '
        'weight, same next step', () async {
      final navigation = MockNavigationService();
      final preferences = FakeUserPreferences();
      final controller = ConsentController(navigation, preferences);

      await controller.reject();

      expect(
        (await preferences.getAll())[consentAcceptedPreferenceKey],
        isFalse,
      );
      verify(navigation.go(const OnboardingRoute().location)).called(1);
    });

    test('openSettings pushes Settings > Privacy without leaving this '
        'screen behind', () {
      final navigation = MockNavigationService();
      ConsentController(navigation, FakeUserPreferences()).openSettings();

      verify(navigation.push(const PrivacySettingsRoute().location)).called(1);
    });
  });
}
