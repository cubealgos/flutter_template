/// Which step of the email-code flow `SignInView` is on.
enum SignInStep {
  /// Entering an email address, before a code has been requested.
  emailEntry,

  /// A code was requested; waiting for the user to enter it.
  codeEntry,

  /// The App Review demo shortcut was tapped; waiting for the reviewer to
  /// enter the shared review code (see
  /// `SignInController.continueAsReviewer`).
  reviewCode,
}
