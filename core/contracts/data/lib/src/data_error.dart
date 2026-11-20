/// Every error a `DocumentRepository` or `StorageService` method can fail
/// with.
///
/// A sealed class instead of stringly-typed errors, matching
/// `package:auth`'s `AuthError` — see that class's dartdoc for the
/// reasoning. Every variant implements [Exception].
sealed class DataError implements Exception {
  /// Creates an error with a developer-facing [message] (for logs, not
  /// UI).
  const DataError(this.message);

  /// A developer-facing description, not localized.
  final String message;

  // No `toString` override — see `AuthError`'s dartdoc for why (matches
  // `package:auth`'s error hierarchy).
}

/// No document/file exists with the given ID.
final class DataNotFoundError extends DataError {
  /// Creates a not-found error.
  const DataNotFoundError(super.message);
}

/// The operation needs a signed-in user, but there isn't one.
final class DataUnauthenticatedError extends DataError {
  /// Creates an unauthenticated error.
  const DataUnauthenticatedError(super.message);
}

/// The current user isn't allowed to read/write this document or file
/// (e.g. it belongs to someone else).
final class DataPermissionError extends DataError {
  /// Creates a permission error.
  const DataPermissionError(super.message);
}

/// An update was refused because the document changed since the caller read
/// it: its `expectedVersion` is no longer the document's `Document.version`.
/// Re-read, reapply the change, and try again.
final class DataConflictError extends DataError {
  /// Creates a conflict error.
  const DataConflictError(super.message);
}

/// The device couldn't reach the backend at all.
final class DataNetworkError extends DataError {
  /// Creates a network error, optionally wrapping the underlying [cause].
  const DataNetworkError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}

/// Anything else — see `AuthUnknownError`'s dartdoc for why this stays a
/// single catch-all.
final class DataUnknownError extends DataError {
  /// Creates an unknown error, optionally wrapping the underlying [cause].
  const DataUnknownError(super.message, {this.cause});

  /// The underlying exception, if any.
  final Object? cause;
}
