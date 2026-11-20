import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:app/features/consent/consent_model.dart';
import 'package:data/data.dart';
import 'package:mvc/mvc.dart';

/// Drives `ConsentView`: Accept and Reject are equal-weight actions —
/// neither is pre-selected and both store the same way, satisfying §25
/// TDDDG / the Planet49 and LG München I rulings this screen exists for
/// (see the plan's "Default screens" section).
///
/// The choice is stored per user via [UserPreferences], not locally —
/// withdrawable later from Settings → Privacy
/// (`PrivacySettingsController`), which reads and writes the same
/// [consentAcceptedPreferenceKey].
class ConsentController extends ViewController<ConsentModel> {
  /// Creates the controller with [_navigation] and [_preferences]
  /// injected.
  ConsentController(this._navigation, this._preferences)
    : super(const ConsentModel());

  final NavigationService _navigation;
  final UserPreferences _preferences;

  /// Records acceptance and moves on to onboarding.
  Future<void> accept() => _decide(accepted: true);

  /// Records rejection and moves on to onboarding — exactly the same
  /// weight and the same next step as [accept]; rejecting never blocks
  /// progress.
  Future<void> reject() => _decide(accepted: false);

  /// Opens Settings → Privacy, so the user can read more before deciding
  /// without losing this screen (`push`, not `go`).
  void openSettings() =>
      _navigation.push(const PrivacySettingsRoute().location);

  Future<void> _decide({required bool accepted}) async {
    await _preferences.update(<String, dynamic>{
      consentAcceptedPreferenceKey: accepted,
    });
    _navigation.go(const OnboardingRoute().location);
  }
}
