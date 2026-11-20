/// The stored consent choice, read from `UserPreferences` — see
/// `PrivacySettingsController`.
enum ConsentStatus {
  /// The user accepted.
  accepted,

  /// The user rejected.
  rejected,

  /// No choice has been made yet (the consent sheet was never shown, or
  /// `AppConfig.consentSheet` is off).
  notSet,
}
