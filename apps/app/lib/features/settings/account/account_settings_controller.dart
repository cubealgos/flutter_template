import 'dart:async';

import 'package:app/app/router.dart';
import 'package:app/features/settings/account/account_delete_error.dart';
import 'package:app/features/settings/account/account_settings_model.dart';
import 'package:app/features/settings/account/widgets/account_delete_confirm_dialog.dart';
import 'package:auth/auth.dart';
import 'package:mvc/mvc.dart';

/// Drives `AccountSettingsView`: lists and disconnects linked social
/// identities, and deletes the account — confirm dialog, then
/// [AuthService.deleteAccount], then back to sign-in, with **no
/// support-ticket step** (see the plan's "Settings → Account" default
/// screen).
class AccountSettingsController extends ViewController<AccountSettingsModel> {
  /// Creates the controller with every service it needs injected.
  AccountSettingsController(this._navigation, this._auth, this._dialogService)
    : super(const AccountSettingsModel());

  final NavigationService _navigation;
  final AuthService _auth;
  final DialogService _dialogService;

  @override
  void init() {
    unawaited(_loadIdentities());
  }

  /// Disconnects the identity with [identityId], then refreshes the list.
  Future<void> disconnect(String identityId) async {
    await _auth.unlinkIdentity(identityId);
    await _loadIdentities();
  }

  /// Shows the delete-account confirmation dialog and, if confirmed,
  /// deletes the account and returns to sign-in. A refusal (the user owns
  /// teams) or any other failure stays on this screen, as
  /// [AccountSettingsModel.deleteError].
  Future<void> confirmAndDeleteAccount() async {
    final confirmed = await _dialogService.show<bool>(
      (_) => AccountDeleteConfirmDialog(
        onConfirm: () => _dialogService.close(true),
        onCancel: () => _dialogService.close(false),
      ),
    );
    if (confirmed != true) return;

    try {
      await _auth.deleteAccount();
    } on AuthOwnsTeamsError catch (e) {
      value = value.copyWith(
        deleteError: AccountDeleteError.ownsTeams,
        ownedTeamNames: e.teamNames,
      );

      return;
    } on AuthError {
      value = value.copyWith(deleteError: AccountDeleteError.generic);

      return;
    }
    _navigation.go(const SignInRoute().location);
  }

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }

  Future<void> _loadIdentities() async {
    try {
      final identities = await _auth.listIdentities();
      value = value.copyWith(identities: identities, loading: false);
    } on AuthError {
      value = value.copyWith(loading: false);
    }
  }
}
