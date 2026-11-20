import 'package:jobs/src/job.dart';
import 'package:jobs/src/job_claim.dart';
import 'package:jobs/src/job_status.dart';

/// The persistence seam of `JobQueueEngine`: what a backend must offer.
///
/// **The only atomic operation it needs is [insertClaim] rejecting a
/// duplicate (job id, attempt)** - a unique index. There is deliberately no
/// conditional update: TablesDB has none, so everything else the engine does
/// is a read followed by a write, made safe by that one rule. A job row's
/// stored status is only a cache that narrows [nextCandidates]; the truth is
/// always `statusOf` over the claims.
abstract interface class JobStore {
  /// Stores a new job (cached status queued).
  Future<void> insertJob(Job job);

  /// The job with [id], or null.
  Future<Job?> findJob(String id);

  /// Jobs that may be claimable at [now], at most [limit]: those cached as
  /// queued whose `availableAt` has passed, in `Job.sortKey` order, then
  /// those cached as running whose cached lease end has passed. Only [types]
  /// when it is non-null. A candidate may turn out not claimable (the cache
  /// can lag): the engine checks each against its claims.
  Future<List<Job>> nextCandidates({
    required DateTime now,
    required int limit,
    Set<String>? types,
  });

  /// Updates the cached status of [jobId] (and, for running, the cached
  /// lease end).
  Future<void> setJobStatus(
    String jobId,
    JobStatus status, {
    DateTime? leaseUntil,
  });

  /// Every claim of [jobId], any order.
  Future<List<JobClaim>> claimsOf(String jobId);

  /// Stores [claim]; throws `DuplicateClaimError` when its (job id, attempt)
  /// exists. This must be atomic.
  Future<void> insertClaim(JobClaim claim);

  /// Replaces the stored claim with [claim]'s (job id, attempt).
  Future<void> updateClaim(JobClaim claim);
}
