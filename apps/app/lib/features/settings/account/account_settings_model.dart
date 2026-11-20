import 'package:app/features/settings/account/account_delete_error.dart';
import 'package:auth/auth.dart';
import 'package:mvc/mvc.dart';

/// `AccountSettingsView`'s view model: the linked social identities and
/// whether they're still loading.
///
/// Not `freezed`: [LinkedIdentity] has no value equality of its own (a
/// plain class from `package:auth`), so a freezed wrapper around a list of
/// them would gain nothing over a small hand-written `copyWith`.
class AccountSettingsModel implements ViewModel {
  /// Creates the model.
  const AccountSettingsModel({
    this.deleteError,
    this.identities = const <LinkedIdentity>[],
    this.loading = true,
    this.ownedTeamNames = const <String>[],
  });

  /// The current account's linked social identities.
  final List<LinkedIdentity> identities;

  /// Whether [identities] is still loading.
  final bool loading;

  /// Why the last account-deletion attempt failed, if it did.
  final AccountDeleteError? deleteError;

  /// The teams the user owns, when [deleteError] is
  /// [AccountDeleteError.ownsTeams].
  final List<String> ownedTeamNames;

  /// Returns a copy with [identities] and/or [loading] replaced, and the
  /// deletion failure replaced (not merged: passing no [deleteError] clears
  /// it) so a new attempt starts from a clean slate.
  AccountSettingsModel copyWith({
    List<LinkedIdentity>? identities,
    bool? loading,
    AccountDeleteError? deleteError,
    List<String> ownedTeamNames = const <String>[],
  }) => AccountSettingsModel(
    identities: identities ?? this.identities,
    loading: loading ?? this.loading,
    deleteError: deleteError,
    ownedTeamNames: ownedTeamNames,
  );
}
