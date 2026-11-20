import 'package:jobs/src/duplicate_claim_error.dart';
import 'package:jobs/src/job.dart';
import 'package:jobs/src/job_claim.dart';
import 'package:jobs/src/job_status.dart';
import 'package:jobs/src/job_store.dart';

class _Cached {
  _Cached(this.job);

  final Job job;
  JobStatus status = JobStatus.queued;
  DateTime? leaseUntil;
}

/// An in-memory [JobStore] for tests.
///
/// Enforces the one rule a real store must: [insertClaim] is atomic and
/// rejects a duplicate (job id, attempt). Every method yields to the event
/// loop first, so two concurrent engine calls really interleave their reads
/// and writes the way two Function executions would.
class InMemoryJobStore implements JobStore {
  final Map<String, _Cached> _jobs = <String, _Cached>{};
  final Map<String, JobClaim> _claims = <String, JobClaim>{};

  /// Every stored claim, for assertions.
  List<JobClaim> get claims => _claims.values.toList();

  /// The cached status of [jobId], for assertions.
  JobStatus? cachedStatus(String jobId) => _jobs[jobId]?.status;

  static String _key(String jobId, int attempt) => '$jobId#$attempt';

  @override
  Future<void> insertJob(Job job) async {
    await Future<void>.delayed(Duration.zero);
    _jobs[job.id] = _Cached(job);
  }

  @override
  Future<Job?> findJob(String id) async {
    await Future<void>.delayed(Duration.zero);

    return _jobs[id]?.job;
  }

  @override
  Future<List<Job>> nextCandidates({
    required DateTime now,
    required int limit,
    Set<String>? types,
  }) async {
    await Future<void>.delayed(Duration.zero);
    bool typeOk(Job job) => types == null || types.contains(job.type);
    final queued =
        _jobs.values
            .where(
              (c) =>
                  c.status == JobStatus.queued &&
                  !c.job.availableAt.isAfter(now) &&
                  typeOk(c.job),
            )
            .map((c) => c.job)
            .toList()
          ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final expired = _jobs.values
        .where(
          (c) =>
              c.status == JobStatus.running &&
              !(c.leaseUntil?.isAfter(now) ?? false) &&
              typeOk(c.job),
        )
        .map((c) => c.job);

    return <Job>[...queued, ...expired].take(limit).toList();
  }

  @override
  Future<void> setJobStatus(
    String jobId,
    JobStatus status, {
    DateTime? leaseUntil,
  }) async {
    await Future<void>.delayed(Duration.zero);
    final cached = _jobs[jobId];
    if (cached == null) return;
    cached
      ..status = status
      ..leaseUntil = leaseUntil;
  }

  @override
  Future<List<JobClaim>> claimsOf(String jobId) async {
    await Future<void>.delayed(Duration.zero);

    return _claims.values.where((c) => c.jobId == jobId).toList();
  }

  @override
  Future<void> insertClaim(JobClaim claim) async {
    await Future<void>.delayed(Duration.zero);
    final key = _key(claim.jobId, claim.attempt);
    if (_claims.containsKey(key)) {
      throw DuplicateClaimError(claim.jobId, claim.attempt);
    }
    _claims[key] = claim;
  }

  @override
  Future<void> updateClaim(JobClaim claim) async {
    await Future<void>.delayed(Duration.zero);
    _claims[_key(claim.jobId, claim.attempt)] = claim;
  }
}
