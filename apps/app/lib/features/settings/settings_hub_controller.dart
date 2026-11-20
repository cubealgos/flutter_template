import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/settings/settings_hub_model.dart';
import 'package:mvc/mvc.dart';

/// Drives `SettingsHubView`: navigates to each settings section.
class SettingsHubController extends ViewController<SettingsHubModel> {
  /// Creates the controller, reading [config] once for the Subscription
  /// row's visibility.
  SettingsHubController(this._navigation, AppConfig config)
    : super(SettingsHubModel(showPaywall: config.paywall));

  final NavigationService _navigation;

  /// Opens Settings → Legal.
  void openLegal() => _navigation.push(const LegalHubRoute().location);

  /// Opens Settings → Privacy.
  void openPrivacy() => _navigation.push(const PrivacySettingsRoute().location);

  /// Opens Settings → Account.
  void openAccount() => _navigation.push(const AccountSettingsRoute().location);

  /// Opens Settings → Teams.
  void openTeams() => _navigation.push(const TeamsRoute().location);

  /// Opens the subscription (billing) screen.
  void openPaywall() => _navigation.push(const PaywallRoute().location);

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }
}
