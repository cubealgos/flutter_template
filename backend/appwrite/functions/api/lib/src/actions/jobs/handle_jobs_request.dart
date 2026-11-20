import 'dart:io';

import 'package:api/src/function_response.dart';
import 'package:jobs/jobs.dart';

/// The Function variable listing the Appwrite user IDs allowed to call the
/// `jobs` action, comma separated. **Unset or empty means nobody**: the
/// action refuses every call (403) until a worker identity is configured.
const String jobsWorkerUsersEnvKey = 'JOBS_WORKER_USER_IDS';

/// The longest lease a caller may ask for, in seconds.
const int maxLeaseSeconds = 3600;

/// The attempts a job gets when the caller names none.
const int defaultMaxAttempts = 3;

/// The HTTP status of a successful call.
const int okStatusCode = HttpStatus.ok;

/// The allow-listed worker user IDs in [environment].
Set<String> workerUsersFrom(Map<String, String> environment) => <String>{
  for (final id in (environment[jobsWorkerUsersEnvKey] ?? '').split(','))
    if (id.trim().isNotEmpty) id.trim(),
};

/// Runs one queue operation for [callerUserId] and builds the response.
///
/// The body is `{"op": <JobQueue method>, ...}` in `JobWire`'s shape.
/// **Authorisation:** the caller must be one of [workerUserIds]. The
/// identity is the router's `x-appwrite-user-id` header, which Appwrite sets
/// and a client cannot forge; the action deliberately has no shared secret
/// in the body, because an execution's request body is kept in its log. A
/// worker outside Appwrite is therefore a dedicated Appwrite user it signs in
/// as; revoking the worker is deleting that user or its sessions.
///
/// Every `JobError` becomes its wire status and body; anything else
/// propagates to the router, which answers 500.
Future<FunctionResponse> handleJobsRequest({
  required String? callerUserId,
  required Set<String> workerUserIds,
  required Map<String, dynamic> body,
  required JobQueue queue,
}) async {
  if (callerUserId == null || !workerUserIds.contains(callerUserId)) {
    return _failure(
      const JobPermissionError('This caller is not a configured job worker.'),
    );
  }
  try {
    final result = await _run(queue, body);

    return FunctionResponse(
      body: <String, dynamic>{'result': result},
      statusCode: okStatusCode,
    );
  } on JobError catch (e) {
    return _failure(e);
  }
}

typedef _Op = Future<Object?> Function(JobQueue queue, Map<String, dynamic>);

/// One handler per wire operation; the names are `JobQueue`'s method names.
final Map<String, _Op> _ops = <String, _Op>{
  'enqueue': _enqueue,
  'claim': _claim,
  'heartbeat': _heartbeat,
  'complete': _complete,
  'fail': _fail,
  'release': _release,
  'status': _status,
};

Future<Object?> _run(JobQueue queue, Map<String, dynamic> body) {
  final op = body['op'];
  if (op is! String) {
    throw const JobInvalidError('The body must carry the operation in "op".');
  }
  final handler = _ops[op];
  if (handler == null) throw JobInvalidError('Unknown operation "$op".');

  return handler(queue, body);
}

Future<Object?> _enqueue(JobQueue queue, Map<String, dynamic> body) async =>
    JobWire.encodeJob(
      await queue.enqueue(
        NewJob(
          type: _string(body, 'type'),
          availableAt: _time(body['availableAt']),
          payload: _map(body['payload'], 'payload'),
          priority: _priority(body['priority']),
          maxAttempts: _int(
            body['maxAttempts'],
            'maxAttempts',
            fallback: defaultMaxAttempts,
          ),
        ),
      ),
    );

Future<Object?> _claim(JobQueue queue, Map<String, dynamic> body) async {
  final lease = await queue.claim(
    workerId: _string(body, 'workerId'),
    leaseFor: _lease(body),
    types: _types(body['types']),
  );

  return lease == null ? null : JobWire.encodeLease(lease);
}

Future<Object?> _heartbeat(JobQueue queue, Map<String, dynamic> body) async =>
    JobWire.encodeLease(
      await queue.heartbeat(_leaseOf(body), leaseFor: _lease(body)),
    );

Future<Object?> _complete(JobQueue queue, Map<String, dynamic> body) async {
  await queue.complete(_leaseOf(body), result: _map(body['result'], 'result'));

  return null;
}

Future<Object?> _fail(JobQueue queue, Map<String, dynamic> body) async {
  await queue.fail(_leaseOf(body), error: _string(body, 'error'));

  return null;
}

Future<Object?> _release(JobQueue queue, Map<String, dynamic> body) async {
  await queue.release(_leaseOf(body));

  return null;
}

Future<Object?> _status(JobQueue queue, Map<String, dynamic> body) async =>
    (await queue.status(_string(body, 'jobId'))).name;

String _string(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value is String && value.isNotEmpty) return value;
  throw JobInvalidError('"$key" must be a non-empty string.');
}

Map<String, dynamic> _map(Object? value, String key) {
  if (value == null) return const <String, dynamic>{};
  if (value is Map) return Map<String, dynamic>.from(value);
  throw JobInvalidError('"$key" must be an object.');
}

int _int(Object? value, String key, {int? fallback}) {
  if (value == null && fallback != null) return fallback;
  if (value is int) return value;
  throw JobInvalidError('"$key" must be an integer.');
}

JobPriority _priority(Object? value) {
  if (value == null) return JobPriority.normal;
  for (final priority in JobPriority.values) {
    if (priority.name == value) return priority;
  }
  throw const JobInvalidError('"priority" must be high, normal or low.');
}

DateTime? _time(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw const JobInvalidError('"availableAt" must be an ISO-8601 time.');
}

Set<String>? _types(Object? value) {
  if (value == null) return null;
  if (value is List && value.every((t) => t is String)) {
    return value.cast<String>().toSet();
  }
  throw const JobInvalidError('"types" must be a list of strings.');
}

Duration _lease(Map<String, dynamic> body) {
  final seconds = _int(body['leaseSeconds'], 'leaseSeconds');
  if (seconds < 1 || seconds > maxLeaseSeconds) {
    throw const JobInvalidError(
      '"leaseSeconds" must be between 1 and $maxLeaseSeconds.',
    );
  }

  return Duration(seconds: seconds);
}

JobLease _leaseOf(Map<String, dynamic> body) {
  final lease = body['lease'];
  if (lease is! Map) throw const JobInvalidError('"lease" must be an object.');
  try {
    return JobWire.decodeLease(Map<String, dynamic>.from(lease));
  } on Object {
    throw const JobInvalidError('"lease" is malformed.');
  }
}

FunctionResponse _failure(JobError error) => FunctionResponse(
  body: JobWire.encodeError(error),
  statusCode: JobWire.statusFor(error),
);
