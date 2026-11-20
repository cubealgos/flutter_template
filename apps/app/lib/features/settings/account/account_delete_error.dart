/// A typed account-deletion failure — the view switches on this to choose
/// its own translated copy, matching `package:auth`'s `AuthError`
/// convention.
enum AccountDeleteError {
  /// The user still owns at least one team (the names are in
  /// `AccountSettingsModel.ownedTeamNames`): they must transfer ownership
  /// or delete the team first. Nothing was deleted.
  ownsTeams,

  /// Anything else went wrong; the account may still exist.
  generic,
}
