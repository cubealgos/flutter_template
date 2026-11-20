import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/api_client.dart';
import 'package:jobs/jobs.dart';

/// The name of the router action this queue calls.
const String jobsAction = 'jobs';

/// The [JobQueue] backed by the `jobs` action of the `api` Function.
///
/// Every state change goes through that one action, which runs `JobQueueEngine`
/// over the `serverOnly` `jobs` and `job_claims` tables (see
/// `backend/appwrite/README.md`, "Background work"). The caller must be a
/// **worker identity**: an Appwrite user whose ID is in the Function's
/// `JOBS_WORKER_USER_IDS` variable, because the action trusts only the router's
/// `x-appwrite-user-id` header, never a secret in the body (an execution's body
/// is stored in its logs). A worker outside Appwrite (a separate scanner
/// service, say) signs in as that user and builds an [ApiClient] over its own
/// executor, e.g. `ApiClient.withExecutor`; anything inside the Function uses
/// `JobQueueEngine` directly instead of calling itself.
class AppwriteJobQueue implements JobQueue {
  /// Creates a queue calling the Function through [client].
  AppwriteJobQueue(Client client) : _api = ApiClient(Functions(client));

  /// Creates a queue over an `ApiClient`, for tests and non-Flutter workers.
  AppwriteJobQueue.withApi(this._api);

  final ApiClient _api;

  @override
  Future<Job> enqueue(NewJob job) async => JobWire.decodeJob(
    await _object('enqueue', <String, dynamic>{
      'type': job.type,
      'payload': job.payload,
      'priority': job.priority.name,
      'maxAttempts': job.maxAttempts,
      'availableAt': ?job.availableAt?.toUtc().toIso8601String(),
    }),
  );

  @override
  Future<JobLease?> claim({
    required String workerId,
    required Duration leaseFor,
    Set<String>? types,
  }) async {
    final result = await _call('claim', <String, dynamic>{
      'workerId': workerId,
      'leaseSeconds': leaseFor.inSeconds,
      'types': ?types?.toList(),
    });

    return result is Map<String, dynamic> ? JobWire.decodeLease(result) : null;
  }

  @override
  Future<JobLease> heartbeat(
    JobLease lease, {
    required Duration leaseFor,
  }) async => JobWire.decodeLease(
    await _object('heartbeat', <String, dynamic>{
      'lease': JobWire.encodeLease(lease),
      'leaseSeconds': leaseFor.inSeconds,
    }),
  );

  @override
  Future<void> complete(
    JobLease lease, {
    Map<String, dynamic> result = const <String, dynamic>{},
  }) async {
    await _call('complete', <String, dynamic>{
      'lease': JobWire.encodeLease(lease),
      'result': result,
    });
  }

  @override
  Future<void> fail(JobLease lease, {required String error}) async {
    await _call('fail', <String, dynamic>{
      'lease': JobWire.encodeLease(lease),
      'error': error,
    });
  }

  @override
  Future<void> release(JobLease lease) async {
    await _call('release', <String, dynamic>{
      'lease': JobWire.encodeLease(lease),
    });
  }

  @override
  Future<JobStatus> status(String jobId) async {
    final result = await _call('status', <String, dynamic>{'jobId': jobId});
    if (result is! String) {
      throw const JobInvalidError('jobs answered status with no name.');
    }

    return JobWire.decodeStatus(result);
  }

  Future<Map<String, dynamic>> _object(
    String op,
    Map<String, dynamic> fields,
  ) async {
    final result = await _call(op, fields);
    if (result is Map<String, dynamic>) return result;
    throw JobInvalidError('jobs answered $op with no object.');
  }

  /// Runs [op] and returns the response's `result`, or throws the
  /// `JobError` the action reported.
  Future<Object?> _call(String op, Map<String, dynamic> fields) async {
    try {
      final body = await _api.call(
        jobsAction,
        fields: <String, dynamic>{'op': op, ...fields},
      );
      final decoded = jsonDecode(body);

      return decoded is Map<String, dynamic> ? decoded['result'] : null;
    } on AppwriteException catch (e) {
      // `ApiClient` reports an action's own failure as "<action> returned
      // <status>: <json body>"; anything else is a transport failure.
      final message = e.message ?? '';
      final brace = message.indexOf('{');
      if (!message.startsWith('$jobsAction returned') || brace < 0) rethrow;
      final Object? body;
      try {
        body = jsonDecode(message.substring(brace));
      } on FormatException {
        rethrow;
      }
      if (body is Map<String, dynamic> && body['error'] is Map) {
        throw JobWire.decodeError(body);
      }
      rethrow;
    }
  }
}
