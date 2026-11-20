/// Every error a `JobQueue` method can fail with.
///
/// A sealed class, matching `TeamError` and `AuthError`. Every variant
/// implements [Exception].
sealed class JobError implements Exception {
  /// Creates an error with a developer-facing [message].
  const JobError(this.message);

  /// A developer-facing description, not localized.
  final String message;
}

/// There is no such job.
final class JobNotFoundError extends JobError {
  /// Creates a not-found error.
  const JobNotFoundError(super.message);
}

/// The caller's lease is no longer the job's latest live attempt: it expired
/// and another worker took over, or the attempt already ended. The write was
/// rejected; the worker must drop the work.
final class JobLeaseLostError extends JobError {
  /// Creates a lease-lost error.
  const JobLeaseLostError(super.message);
}

/// The request itself is malformed.
final class JobInvalidError extends JobError {
  /// Creates an invalid-request error.
  const JobInvalidError(super.message);
}

/// The caller is not a worker identity this queue accepts.
final class JobPermissionError extends JobError {
  /// Creates a permission error.
  const JobPermissionError(super.message);
}
