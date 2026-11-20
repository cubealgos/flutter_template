/// Every error a `TeamService` method can fail with.
///
/// A sealed class, matching `package:auth`'s `AuthError` — see that class's
/// dartdoc for the reasoning. Every variant implements [Exception].
sealed class TeamError implements Exception {
  /// Creates an error with a developer-facing [message] (for logs, not UI).
  const TeamError(this.message);

  /// A developer-facing description, not localized.
  final String message;

  // No `toString` override — see `AuthError`'s dartdoc for why.
}

/// There is no such team, invitation or member **as far as the caller may
/// know**: a non-member gets this for a team that exists, so the error never
/// reveals another tenant's teams.
final class TeamNotFoundError extends TeamError {
  /// Creates a not-found error.
  const TeamNotFoundError(super.message);
}

/// The operation needs a signed-in user, but there isn't one.
final class TeamUnauthenticatedError extends TeamError {
  /// Creates an unauthenticated error.
  const TeamUnauthenticatedError(super.message);
}

/// The caller is a member but their role doesn't allow this (a member
/// inviting, an admin removing another admin).
final class TeamPermissionError extends TeamError {
  /// Creates a permission error.
  const TeamPermissionError(super.message);
}

/// The operation would break a team rule: a second owner, a team without
/// its owner, an unknown role, a blank name. The team is unchanged.
final class TeamInvariantError extends TeamError {
  /// Creates an invariant error.
  const TeamInvariantError(super.message);
}

/// The invitation can't be used: already answered, revoked, expired, or a
/// duplicate of one still pending.
final class TeamInvitationError extends TeamError {
  /// Creates an invitation error.
  const TeamInvitationError(super.message);
}

/// The device couldn't reach the backend at all.
final class TeamNetworkError extends TeamError {
  /// Creates a network error, optionally wrapping the underlying [cause].
  const TeamNetworkError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}

/// Anything else — see `AuthUnknownError`'s dartdoc for why this stays a
/// single catch-all.
final class TeamUnknownError extends TeamError {
  /// Creates an unknown error, optionally wrapping the underlying [cause].
  const TeamUnknownError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}
