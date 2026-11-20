/// Where the data-export flow currently is — step-up re-verification
/// (re-entering an email code) before the export itself runs.
enum ExportPhase {
  /// Not exporting.
  idle,

  /// Waiting for the user to enter the step-up code just requested.
  stepUp,

  /// The code was verified; the export itself is running.
  exporting,

  /// The export finished — `PrivacySettingsModel.exportedJson` holds the
  /// result.
  result,
}
