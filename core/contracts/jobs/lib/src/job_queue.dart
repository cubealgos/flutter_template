import 'package:jobs/src/job.dart';
import 'package:jobs/src/job_lease.dart';
import 'package:jobs/src/job_status.dart';
import 'package:jobs/src/new_job.dart';

/// A leased job queue: producers [enqueue], workers [claim], extend with
/// [heartbeat] and end with [complete], [fail] or [release].
///
/// **Delivery is at least once.** A worker that stalls past its lease loses
/// the job to another; both may finish the work, so handlers must be
/// idempotent. What the queue guarantees is that exactly one attempt is the
/// job's latest, and that a write from any other attempt is rejected with
/// `JobLeaseLostError` - a stale worker can never overwrite the real result.
///
/// Every method may throw `JobNotFoundError`; the lease-taking ones
/// `JobLeaseLostError`.
abstract interface class JobQueue {
  /// Enqueues [job] and returns the stored job, with its ID.
  Future<Job> enqueue(NewJob job);

  /// Claims the best claimable job (highest band, then oldest; only [types]
  /// when given) for [workerId], holding it for [leaseFor]. Null when there
  /// is none. Of any number of concurrent calls for one job, exactly one
  /// gets it.
  Future<JobLease?> claim({
    required String workerId,
    required Duration leaseFor,
    Set<String>? types,
  });

  /// Extends [lease] to [leaseFor] from now and returns the new lease.
  /// Throws `JobLeaseLostError` if it is no longer the job's latest attempt.
  Future<JobLease> heartbeat(JobLease lease, {required Duration leaseFor});

  /// Ends [lease]'s attempt successfully, with [result].
  Future<void> complete(
    JobLease lease, {
    Map<String, dynamic> result = const <String, dynamic>{},
  });

  /// Ends [lease]'s attempt as failed with [error]; the job is queued again
  /// while it has attempts left, dead otherwise.
  Future<void> fail(JobLease lease, {required String error});

  /// Gives the job back without using up an attempt.
  Future<void> release(JobLease lease);

  /// The status of the job with [jobId].
  Future<JobStatus> status(String jobId);
}
