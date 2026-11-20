import 'package:jobs/src/job.dart';

/// What a successful claim hands the worker: the [job] and the proof of its
/// attempt, which every later call (heartbeat, complete, fail, release) must
/// present.
class JobLease {
  /// Creates a lease.
  const JobLease({
    required this.job,
    required this.attempt,
    required this.workerId,
    required this.leaseExpiresAt,
  });

  /// The claimed job.
  final Job job;

  /// The attempt number this lease is for.
  final int attempt;

  /// The worker that holds it.
  final String workerId;

  /// When it runs out unless extended by a heartbeat.
  final DateTime leaseExpiresAt;

  /// The same lease with a new expiry.
  JobLease extendedTo(DateTime leaseExpiresAt) => JobLease(
    job: job,
    attempt: attempt,
    workerId: workerId,
    leaseExpiresAt: leaseExpiresAt,
  );
}
