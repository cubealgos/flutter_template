import 'package:jobs/src/job.dart';
import 'package:jobs/src/job_error.dart';
import 'package:jobs/src/job_lease.dart';
import 'package:jobs/src/job_priority.dart';
import 'package:jobs/src/job_status.dart';

/// The JSON `backend/appwrite/functions/api`'s `jobs` action and
/// `AppwriteJobQueue` speak to each other, so the two ends can't drift.
///
/// A request is `{"action": "jobs", "op": <JobQueue method name>, ...}`; a
/// success is `{"result": ...}`; a failure is `{"error": {"code": ...,
/// "message": ...}}` with the status [statusFor] gives.
abstract final class JobWire {
  static const int _badRequest = 400;
  static const int _forbidden = 403;
  static const int _notFound = 404;
  static const int _conflict = 409;

  /// Encodes [job].
  static Map<String, dynamic> encodeJob(Job job) => <String, dynamic>{
    'id': job.id,
    'type': job.type,
    'payload': job.payload,
    'priority': job.priority.name,
    'maxAttempts': job.maxAttempts,
    'availableAt': job.availableAt.toUtc().toIso8601String(),
    'createdAt': job.createdAt.toUtc().toIso8601String(),
  };

  /// Decodes a job encoded by [encodeJob].
  static Job decodeJob(Map<String, dynamic> json) => Job(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    priority: JobPriority.values.byName(json['priority'] as String),
    maxAttempts: json['maxAttempts'] as int,
    availableAt: DateTime.parse(json['availableAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// Encodes [lease].
  static Map<String, dynamic> encodeLease(JobLease lease) => <String, dynamic>{
    'job': encodeJob(lease.job),
    'attempt': lease.attempt,
    'workerId': lease.workerId,
    'leaseExpiresAt': lease.leaseExpiresAt.toUtc().toIso8601String(),
  };

  /// Decodes a lease encoded by [encodeLease].
  static JobLease decodeLease(Map<String, dynamic> json) => JobLease(
    job: decodeJob(Map<String, dynamic>.from(json['job'] as Map)),
    attempt: json['attempt'] as int,
    workerId: json['workerId'] as String,
    leaseExpiresAt: DateTime.parse(json['leaseExpiresAt'] as String),
  );

  /// Decodes a status by its name.
  static JobStatus decodeStatus(String name) => JobStatus.values.byName(name);

  /// The error body for [error].
  static Map<String, dynamic> encodeError(JobError error) => <String, dynamic>{
    'error': <String, dynamic>{
      'code': switch (error) {
        JobNotFoundError() => 'not_found',
        JobLeaseLostError() => 'lease_lost',
        JobInvalidError() => 'invalid',
        JobPermissionError() => 'forbidden',
      },
      'message': error.message,
    },
  };

  /// The HTTP status [error] is answered with.
  static int statusFor(JobError error) => switch (error) {
    JobNotFoundError() => _notFound,
    JobLeaseLostError() => _conflict,
    JobInvalidError() => _badRequest,
    JobPermissionError() => _forbidden,
  };

  /// The error an [encodeError] body describes.
  static JobError decodeError(Map<String, dynamic> body) {
    final error = Map<String, dynamic>.from(body['error'] as Map);
    final message = error['message'] as String? ?? '';

    return switch (error['code']) {
      'not_found' => JobNotFoundError(message),
      'lease_lost' => JobLeaseLostError(message),
      'forbidden' => JobPermissionError(message),
      _ => JobInvalidError(message),
    };
  }
}
