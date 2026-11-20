/// Every error an `AuthService` method can fail with.
///
/// A sealed class instead of stringly-typed errors so a caller can
/// `switch` over the concrete cause exhaustively (the analyzer flags a
/// missing case) rather than pattern-matching on an error message. Every
/// variant implements [Exception], so a method that can't recover simply
/// throws one — callers `catch (AuthError e)` or narrow with `on
/// AuthInvalidCodeError catch (e)` for a specific case.
sealed class AuthError implements Exception {
  /// Creates an error with a human-readable [message] (for logs, not UI —
  /// screens should switch on the concrete type to choose their own
  /// user-facing copy, including translations).
  ///
  /// See `AuthService`'s dartdoc for context: every one of that
  /// interface's methods throws a subtype of this class on failure.
  const AuthError(this.message);

  /// A developer-facing description. Not localized and not meant to be
  /// shown to the user directly.
  final String message;

  // No `toString` override here: the obvious `'$runtimeType: $message'`
  // trips solid_lints/no_runtimetype_tostring (`runtimeType` is unreliable
  // once a release build renames/tree-shakes types), and hand-naming the
  // type in every subclass below would just repeat what `catch (on
  // SpecificError)` already tells a caller. [message] alone is enough for
  // a log line; the default `Exception` representation callers get from
  // an un-overridden `toString` already includes it.
}

/// The device couldn't reach the backend at all (offline, DNS failure,
/// timeout, …).
final class AuthNetworkError extends AuthError {
  /// Creates a network error, optionally wrapping the underlying [cause].
  const AuthNetworkError(super.message, {this.cause});

  /// The underlying exception, if any (e.g. a SocketException wrapped by
  /// an HTTP client).
  final Object? cause;
}

/// An email or magic-link/OTP code was wrong.
final class AuthInvalidCodeError extends AuthError {
  /// Creates an invalid-code error.
  const AuthInvalidCodeError(super.message);
}

/// An email or OTP code was valid once but has since expired.
final class AuthCodeExpiredError extends AuthError {
  /// Creates an expired-code error.
  const AuthCodeExpiredError(super.message);
}

/// The backend rate-limited this request (too many code requests/attempts
/// in a short window).
final class AuthRateLimitedError extends AuthError {
  /// Creates a rate-limit error.
  const AuthRateLimitedError(super.message);
}

/// The user closed or cancelled an interactive flow (an OAuth browser tab,
/// a passkey prompt) before it completed. Not a failure to surface as an
/// error banner — a screen typically just returns to its previous state.
final class AuthCancelledError extends AuthError {
  /// Creates a cancellation.
  const AuthCancelledError(super.message);
}

/// The requested flow isn't supported by this backend — see
/// `AuthCapabilities`. A screen should check the relevant capability flag
/// before offering the button in the first place; this is the defensive
/// fallback for a method called anyway.
final class AuthUnsupportedError extends AuthError {
  /// Creates an unsupported-flow error.
  const AuthUnsupportedError(super.message);
}

/// The operation needs a signed-in session, but there isn't one (or it has
/// expired server-side).
final class AuthUnauthenticatedError extends AuthError {
  /// Creates an unauthenticated error.
  const AuthUnauthenticatedError(super.message);
}

/// Account deletion was refused because the user still owns at least one
/// team: deleting the account would leave that team without an owner. The
/// user must transfer ownership of (or delete) each team first. Thrown by
/// `AuthService.deleteAccount`; nothing was deleted.
final class AuthOwnsTeamsError extends AuthError {
  /// Creates the error for the teams named [teamNames].
  const AuthOwnsTeamsError(super.message, {required this.teamNames});

  /// The display names of the teams the user owns, as the backend knows
  /// them — what a screen shows next to its own translated explanation.
  final List<String> teamNames;
}

/// Anything else — a backend error this hierarchy doesn't have a specific
/// variant for. Kept as a single catch-all (not further subdivided) so
/// adding a new specific variant later is additive, not a breaking rename
/// of this one.
final class AuthUnknownError extends AuthError {
  /// Creates an unknown error, optionally wrapping the underlying [cause].
  const AuthUnknownError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}
