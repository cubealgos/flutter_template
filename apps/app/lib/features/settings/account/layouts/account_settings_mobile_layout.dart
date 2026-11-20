import 'package:app/features/settings/account/account_delete_error.dart';
import 'package:app/features/settings/account/account_settings_model.dart';
import 'package:app/features/settings/account/widgets/identities_section.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// Settings → Account: linked social identities (with disconnect) and
/// delete account.
class AccountSettingsMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const AccountSettingsMobileLayout({
    required this.model,
    required this.onBack,
    required this.onDisconnect,
    required this.onDeleteAccount,
    super.key,
  });

  /// The account state being rendered.
  final AccountSettingsModel model;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called with the id of the identity whose disconnect button was pressed.
  final ValueChanged<String> onDisconnect;

  /// Called when the delete-account button is pressed.
  final VoidCallback onDeleteAccount;

  String _errorText(AccountDeleteError error, List<String> teamNames) =>
      switch (error) {
        AccountDeleteError.ownsTeams => t.settings.account.deleteOwnsTeams(
          teams: teamNames.map((n) => '"$n"').join(', '),
        ),
        AccountDeleteError.generic => t.settings.account.deleteFailed,
      };

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: t.settings.account.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StyledText(
            t.settings.account.linkedIdentitiesTitle,
            style: h2Style(),
          ),
          const AppGap.v3(),
          IdentitiesSection(
            loading: model.loading,
            identities: model.identities,
            onDisconnect: onDisconnect,
          ),
          const AppGap.v8(),
          const AppDivider(),
          const AppGap.v8(),
          StyledText(
            t.settings.account.dangerZoneLabel.toUpperCase(),
            style: eyebrowStyle().color(colorDanger()),
          ),
          const AppGap.v3(),
          AppFullWidthButton(
            child: AppButton(
              semanticLabel: t.settings.account.deleteAccountButton,
              onPressed: onDeleteAccount,
              variant: AppButtonVariant.destructiveOutlined,
              child: Text(t.settings.account.deleteAccountButton),
            ),
          ),
          if (model.deleteError case final error?) ...<Widget>[
            const AppGap.v3(),
            StyledText(
              _errorText(error, model.ownedTeamNames),
              style: bodyStyle().color(colorDanger()),
            ),
          ],
        ],
      ),
    );
  }
}
