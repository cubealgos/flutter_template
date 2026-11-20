import 'package:app/features/settings/settings_hub_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The Settings hub: Legal, Privacy, Account and (behind
/// `AppConfig.paywall`) Subscription.
class SettingsHubMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const SettingsHubMobileLayout({
    required this.model,
    required this.onBack,
    required this.onOpenLegal,
    required this.onOpenPrivacy,
    required this.onOpenAccount,
    required this.onOpenTeams,
    required this.onOpenPaywall,
    super.key,
  });

  /// The hub state being rendered.
  final SettingsHubModel model;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called when the Legal row is tapped.
  final VoidCallback onOpenLegal;

  /// Called when the Privacy row is tapped.
  final VoidCallback onOpenPrivacy;

  /// Called when the Account row is tapped.
  final VoidCallback onOpenAccount;

  /// Called when the Teams row is tapped.
  final VoidCallback onOpenTeams;

  /// Called when the Subscription row is tapped.
  final VoidCallback onOpenPaywall;

  @override
  Widget build(BuildContext context) {
    const chevron = AppChevronIcon(
      direction: AppChevronDirection.end,
      color: colorFgSubtle,
    );

    return AppScreenScaffold(
      title: t.settings.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppListTile(
            title: t.settings.legalLink,
            trailing: chevron,
            onTap: onOpenLegal,
          ),
          AppListTile(
            title: t.settings.privacyLink,
            trailing: chevron,
            onTap: onOpenPrivacy,
          ),
          AppListTile(
            title: t.settings.accountLink,
            trailing: chevron,
            onTap: onOpenAccount,
          ),
          AppListTile(
            title: t.settings.teamsLink,
            trailing: chevron,
            onTap: onOpenTeams,
          ),
          if (model.showPaywall)
            AppListTile(
              title: t.settings.paywallLink,
              trailing: chevron,
              onTap: onOpenPaywall,
            ),
        ],
      ),
    );
  }
}
