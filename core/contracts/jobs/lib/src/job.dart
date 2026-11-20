import 'package:jobs/src/job_priority.dart';

/// One unit of background work: what to do ([type], [payload]), not who is
/// doing it or how far it got (that is `JobClaim`s and `JobStatus`).
class Job {
  /// Creates a job.
  const Job({
    required this.id,
    required this.type,
    required this.payload,
    required this.priority,
    required this.maxAttempts,
    required this.availableAt,
    required this.createdAt,
  });

  /// The job's ID.
  final String id;

  /// What kind of work it is; a worker asks for the types it can run.
  final String type;

  /// The work's input, JSON-encodable.
  final Map<String, dynamic> payload;

  /// Its priority band.
  final JobPriority priority;

  /// How many attempts (claims that were not released) it may use before it
  /// is dead.
  final int maxAttempts;

  /// The earliest time it may be claimed.
  final DateTime availableAt;

  /// When it was enqueued.
  final DateTime createdAt;

  /// A string that sorts by priority band, then age: what a store orders its
  /// claimable jobs by.
  String get sortKey =>
      '${priority.rank}-${createdAt.toUtc().toIso8601String()}';
}
