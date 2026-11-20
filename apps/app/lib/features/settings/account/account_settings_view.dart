import 'package:app/app/di.dart';
import 'package:app/features/settings/account/account_settings_controller.dart';
import 'package:app/features/settings/account/account_settings_model.dart';
import 'package:app/features/settings/account/layouts/account_settings_mobile_layout.dart';
import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Settings → Account: linked social identities (with disconnect) and
/// delete account.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `AccountSettingsMobileLayout` (mobile only — every
/// wider viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class AccountSettingsView
    extends ViewWidget<AccountSettingsModel, AccountSettingsController> {
  /// Creates the view.
  AccountSettingsView({super.key});

  @override
  AccountSettingsController createController() => AccountSettingsController(
    getIt<NavigationService>(),
    getIt<AuthService>(),
    getIt<DialogService>(),
  );

  @override
  Widget build(
    BuildContext context,
    AccountSettingsController controller,
    AccountSettingsModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => AccountSettingsMobileLayout(
        model: model,
        onBack: controller.goBack,
        onDisconnect: controller.disconnect,
        onDeleteAccount: controller.confirmAndDeleteAccount,
      ),
    );
  }
}
