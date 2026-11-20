import 'package:jobs/src/job_priority.dart';

/// What a producer asks `JobQueue.enqueue` for: a job's description before it
/// has an ID.
class NewJob {
  /// Describes a job of [type]. [availableAt] delays the first claim (now by
  /// default); [maxAttempts] caps the claims that are not released.
  const NewJob({
    required this.type,
    this.availableAt,
    this.payload = const <String, dynamic>{},
    this.priority = JobPriority.normal,
    this.maxAttempts = 3,
  });

  /// What kind of work it is; a worker asks for the types it can run.
  final String type;

  /// The earliest time it may be claimed; null for now.
  final DateTime? availableAt;

  /// The work's input, JSON-encodable.
  final Map<String, dynamic> payload;

  /// Its priority band.
  final JobPriority priority;

  /// How many attempts it may use before it is dead.
  final int maxAttempts;
}
