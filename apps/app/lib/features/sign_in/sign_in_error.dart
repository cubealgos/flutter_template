/// A typed sign-in failure — the view switches on this to choose its own
/// translated copy, matching `package:auth`'s `AuthError` convention.
/// Deliberately coarse (not one variant per `AuthError` subtype): the plan
/// requires this screen to reveal nothing about *why* email-code sign-in
/// failed beyond "wrong code" vs "everything else", so there is nothing
/// finer for the UI layer to distinguish.
enum SignInError {
  /// Something failed that isn't one of the more specific cases below.
  generic,

  /// The entered code was wrong or expired — the email OTP code, or (see
  /// `SignInController.submitReviewCode`) the App Review shared code.
  invalidCode,

  /// Too many attempts — try again later.
  rateLimited,
}
