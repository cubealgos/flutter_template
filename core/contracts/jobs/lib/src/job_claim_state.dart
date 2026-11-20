/// How one attempt (one `JobClaim`) ended, or that it has not yet.
enum JobClaimState {
  /// The worker holds the lease.
  active,

  /// The worker finished the work.
  completed,

  /// The worker reported a failure.
  failed,

  /// The worker gave the job back without using up an attempt.
  released,
}
