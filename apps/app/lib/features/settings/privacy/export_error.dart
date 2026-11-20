/// A typed export-flow failure — the view switches on this to choose its
/// own translated copy, matching `package:auth`'s `AuthError` convention
/// ("screens should switch on the concrete type to choose their own
/// user-facing copy").
enum ExportError {
  /// The current session has no email to send a step-up code to (e.g. a
  /// passkey session).
  noEmail,

  /// Requesting the step-up code failed.
  requestFailed,

  /// The entered step-up code was wrong or expired.
  invalidCode,
}
