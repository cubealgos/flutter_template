import 'package:jobs/src/job.dart';
import 'package:jobs/src/job_claim.dart';
import 'package:jobs/src/job_claim_state.dart';

/// Where a job is, derived from its claims (see [statusOf]).
enum JobStatus {
  /// Waiting for a worker.
  queued,

  /// A worker holds a live lease.
  running,

  /// The latest attempt completed.
  succeeded,

  /// Out of attempts: it failed or its lease expired every time.
  dead,
}

/// The status of [job] at [now], from its [claims] alone.
///
/// Only the **latest attempt** counts: a completion from an older attempt
/// (a worker that lost its lease and finished anyway) is ignored. Attempts
/// used are the claims that were not released; a job with none left is
/// [JobStatus.dead] instead of [JobStatus.queued].
JobStatus statusOf(Job job, List<JobClaim> claims, DateTime now) {
  if (claims.isEmpty) return JobStatus.queued;
  final latest = latestClaim(claims);
  if (latest.state == JobClaimState.completed) return JobStatus.succeeded;
  if (latest.state == JobClaimState.active &&
      now.isBefore(latest.leaseExpiresAt)) {
    return JobStatus.running;
  }
  final used = claims.where((c) => c.state != JobClaimState.released).length;

  return used >= job.maxAttempts ? JobStatus.dead : JobStatus.queued;
}

/// The claim with the highest attempt number. [claims] must not be empty.
JobClaim latestClaim(List<JobClaim> claims) =>
    claims.reduce((a, b) => b.attempt > a.attempt ? b : a);
