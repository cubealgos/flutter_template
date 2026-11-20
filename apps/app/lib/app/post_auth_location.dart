import 'package:app/app/config.dart';
import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:data/data.dart';

/// Decides where to go right after a session starts (sign-in, or a
/// restored session at bootstrap) — shared by `SignInController` and
/// `BootstrapController` so the two can't drift into different rules.
///
/// Order matches the plan's "Default screens" section: consent (if
/// `AppConfig.consentSheet` is on and no choice has been recorded yet),
/// then onboarding (if its stepper hasn't been walked through to the end
/// yet — see `OnboardingController`), then Home.
Future<String> resolvePostAuthLocation({
  required AppConfig config,
  required UserPreferences preferences,
}) async {
  final prefs = await preferences.getAll();

  if (config.consentSheet && prefs[consentAcceptedPreferenceKey] == null) {
    return const ConsentRoute().location;
  }

  if (prefs[onboardingCompletedPreferenceKey] != true) {
    return const OnboardingRoute().location;
  }

  return const HomeRoute().location;
}
