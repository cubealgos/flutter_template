/// Thrown by `JobStore.insertClaim` when a claim for the same (job id,
/// attempt) already exists: another worker won that attempt.
class DuplicateClaimError implements Exception {
  /// Creates the error.
  const DuplicateClaimError(this.jobId, this.attempt);

  /// The job.
  final String jobId;

  /// The attempt that was already taken.
  final int attempt;
}
