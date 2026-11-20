/// Which legal document `LegalDocumentView` renders — see the plan's
/// "Settings → Legal" default screen: Impressum, Datenschutz, AGB, and
/// Barrierefreiheit (behind `AppConfig.accessibilityStatement`).
enum LegalDocumentType {
  /// § 5 DDG provider identification.
  impressum,

  /// The privacy policy (GDPR Art. 13).
  datenschutz,

  /// Terms & conditions.
  agb,

  /// The accessibility statement.
  barrierefreiheit,
}
