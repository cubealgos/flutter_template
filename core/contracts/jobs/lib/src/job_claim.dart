import 'package:jobs/src/job_claim_state.dart';

/// One attempt at a job: the row a worker wins by inserting it, because a
/// store holds it unique on (`jobId`, `attempt`).
///
/// A result, an error or a lease extension is written **to the claim of its
/// own attempt**, so a stale worker can only ever touch a claim that a newer
/// attempt has already outranked.
class JobClaim {
  /// Creates a claim.
  const JobClaim({
    required this.jobId,
    required this.attempt,
    required this.workerId,
    required this.leaseExpiresAt,
    this.result,
    this.error,
    this.finishedAt,
    this.state = JobClaimState.active,
  });

  /// The job this attempt is for.
  final String jobId;

  /// The attempt number, from 1; unique per job.
  final int attempt;

  /// The worker that holds (or held) it.
  final String workerId;

  /// When the lease runs out unless a heartbeat extends it.
  final DateTime leaseExpiresAt;

  /// How the attempt ended, or [JobClaimState.active].
  final JobClaimState state;

  /// The result a worker completed with.
  final Map<String, dynamic>? result;

  /// The error a worker failed with.
  final String? error;

  /// When the attempt ended.
  final DateTime? finishedAt;

  /// The same claim with its lease extended to [leaseExpiresAt].
  JobClaim withLease(DateTime leaseExpiresAt) => JobClaim(
    jobId: jobId,
    attempt: attempt,
    workerId: workerId,
    leaseExpiresAt: leaseExpiresAt,
  );

  /// The same claim, ended at [at] in [state] (completed, failed or
  /// released), with the attempt's [result] or [error].
  JobClaim ended(
    JobClaimState state, {
    required DateTime at,
    Map<String, dynamic>? result,
    String? error,
  }) => JobClaim(
    jobId: jobId,
    attempt: attempt,
    workerId: workerId,
    leaseExpiresAt: leaseExpiresAt,
    state: state,
    result: result,
    error: error,
    finishedAt: at,
  );
}
