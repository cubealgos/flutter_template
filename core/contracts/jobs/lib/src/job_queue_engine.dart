import 'package:jobs/src/duplicate_claim_error.dart';
import 'package:jobs/src/job.dart';
import 'package:jobs/src/job_claim.dart';
import 'package:jobs/src/job_claim_state.dart';
import 'package:jobs/src/job_error.dart';
import 'package:jobs/src/job_lease.dart';
import 'package:jobs/src/job_queue.dart';
import 'package:jobs/src/job_status.dart';
import 'package:jobs/src/job_store.dart';
import 'package:jobs/src/new_job.dart';

/// How many candidate jobs one [JobQueueEngine.claim] looks at.
const int claimCandidateLimit = 50;

// The engine is mostly calls into its store and the claims it reads: that is
// its job, not envy.
// ignore_for_file: solid_lints/feature_envy

/// The one implementation of the [JobQueue] rules, over a [JobStore].
///
/// **Why claim rows.** Appwrite TablesDB has no compare-and-set update, so a
/// lease can't be "set `leasedBy` where it is still empty". Instead a claim
/// is an *insert* into a store holding it unique on (job id, attempt):
/// concurrent claimers of one job all try to insert attempt `n + 1`, and the
/// store lets exactly one through. Everything after that is derived from the
/// claim rows (`statusOf`), so a crash between two writes can never leave
/// the queue inconsistent - the cached job status is only ever a hint.
///
/// **Stale workers.** A result, a heartbeat or a failure is written to the
/// claim of the lease's own attempt, and only after checking that attempt is
/// still the job's latest claim, held by that worker, and active. The check
/// runs again after the write, so a takeover that raced it is also reported
/// as `JobLeaseLostError`; the stale write itself lands on a claim that
/// `statusOf` ignores, because only the latest attempt counts. The remaining
/// window (a takeover between the check and the write) is therefore harmless
/// to the job's state, though the stale worker may still have done the work:
/// delivery is at least once.
class JobQueueEngine implements JobQueue {
  /// Creates an engine over [store]. [clock] is the
  /// time source (the real clock by default).
  JobQueueEngine({
    required this.store,
    required this.newId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The persistence.
  final JobStore store;

  /// Makes job IDs.
  final String Function() newId;

  final DateTime Function() _clock;

  DateTime _now() => _clock().toUtc();

  @override
  Future<Job> enqueue(NewJob job) async {
    if (job.type.trim().isEmpty) {
      throw const JobInvalidError('A job needs a type.');
    }
    if (job.maxAttempts < 1) {
      throw const JobInvalidError('A job needs at least one attempt.');
    }
    final now = _now();
    final stored = Job(
      id: newId(),
      type: job.type,
      payload: job.payload,
      priority: job.priority,
      maxAttempts: job.maxAttempts,
      availableAt: (job.availableAt ?? now).toUtc(),
      createdAt: now,
    );
    await store.insertJob(stored);

    return stored;
  }

  @override
  Future<JobLease?> claim({
    required String workerId,
    required Duration leaseFor,
    Set<String>? types,
  }) async {
    final now = _now();
    final candidates = await store.nextCandidates(
      now: now,
      limit: claimCandidateLimit,
      types: types,
    );
    for (final job in candidates) {
      final claims = await store.claimsOf(job.id);
      final status = statusOf(job, claims, now);
      if (status != JobStatus.queued) {
        // The cache lagged (a finished or dead job, or a live lease): heal
        // it so the job stops being a candidate.
        if (status != JobStatus.running) {
          await store.setJobStatus(job.id, status);
        }
        continue;
      }
      final attempt = claims.isEmpty ? 1 : latestClaim(claims).attempt + 1;
      final claim = JobClaim(
        jobId: job.id,
        attempt: attempt,
        workerId: workerId,
        leaseExpiresAt: now.add(leaseFor),
      );
      try {
        await store.insertClaim(claim);
      } on DuplicateClaimError {
        // Another worker won this attempt; try the next job.
        continue;
      }
      await store.setJobStatus(
        job.id,
        JobStatus.running,
        leaseUntil: claim.leaseExpiresAt,
      );

      return JobLease(
        job: job,
        attempt: attempt,
        workerId: workerId,
        leaseExpiresAt: claim.leaseExpiresAt,
      );
    }

    return null;
  }

  @override
  Future<JobLease> heartbeat(
    JobLease lease, {
    required Duration leaseFor,
  }) async {
    final claim = await _requireCurrent(lease);
    final until = _now().add(leaseFor);
    await store.updateClaim(claim.withLease(until));
    await _requireStillLatest(lease);
    await store.setJobStatus(
      lease.job.id,
      JobStatus.running,
      leaseUntil: until,
    );

    return lease.extendedTo(until);
  }

  @override
  Future<void> complete(
    JobLease lease, {
    Map<String, dynamic> result = const <String, dynamic>{},
  }) async {
    final claim = await _requireCurrent(lease);
    await store.updateClaim(
      claim.ended(JobClaimState.completed, at: _now(), result: result),
    );
    await _requireStillLatest(lease);
    await store.setJobStatus(lease.job.id, JobStatus.succeeded);
  }

  @override
  Future<void> fail(JobLease lease, {required String error}) async {
    final claim = await _requireCurrent(lease);
    await store.updateClaim(
      claim.ended(JobClaimState.failed, at: _now(), error: error),
    );
    await _requireStillLatest(lease);
    await _refreshStatus(lease.job);
  }

  @override
  Future<void> release(JobLease lease) async {
    final claim = await _requireCurrent(lease);
    await store.updateClaim(claim.ended(JobClaimState.released, at: _now()));
    await _requireStillLatest(lease);
    await _refreshStatus(lease.job);
  }

  @override
  Future<JobStatus> status(String jobId) async {
    final job = await store.findJob(jobId);
    if (job == null) throw JobNotFoundError('No job with id "$jobId".');

    return statusOf(job, await store.claimsOf(jobId), _now());
  }

  Future<void> _refreshStatus(Job job) async {
    final status = statusOf(job, await store.claimsOf(job.id), _now());
    await store.setJobStatus(job.id, status);
  }

  /// The lease's claim, if it is still the job's latest, held by this worker
  /// and active; otherwise throws.
  Future<JobClaim> _requireCurrent(JobLease lease) async {
    final claims = await store.claimsOf(lease.job.id);
    if (claims.isEmpty) {
      throw JobNotFoundError('No claim for job "${lease.job.id}".');
    }
    final latest = latestClaim(claims);
    if (latest.attempt != lease.attempt ||
        latest.workerId != lease.workerId ||
        latest.state != JobClaimState.active) {
      throw JobLeaseLostError(
        'Attempt ${lease.attempt} of job "${lease.job.id}" is no longer the '
        'current one.',
      );
    }

    return latest;
  }

  Future<void> _requireStillLatest(JobLease lease) async {
    final latest = latestClaim(await store.claimsOf(lease.job.id));
    if (latest.attempt != lease.attempt) {
      throw JobLeaseLostError(
        'Job "${lease.job.id}" was taken over by attempt ${latest.attempt}.',
      );
    }
  }
}
