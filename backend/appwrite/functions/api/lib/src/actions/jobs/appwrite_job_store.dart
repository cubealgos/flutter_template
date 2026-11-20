import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as models;
import 'package:jobs/jobs.dart';

/// The `jobs` table's ID.
const String jobsTable = 'jobs';

/// The `job_claims` table's ID.
const String jobClaimsTable = 'job_claims';

/// The page size of every list call; Appwrite's own maximum.
const int _pageSize = 100;

/// The [JobStore] over the `jobs` and `job_claims` tables, with the API key
/// of the execution (never a user's rights).
///
/// A claim is inserted under the row ID `<jobId>_<attempt>`, **and** the
/// table holds (`jobId`, `attempt`) unique: either rejects a second claim of
/// one attempt with a 409, which becomes `DuplicateClaimError`. That is the
/// only atomic step the queue relies on (see `JobQueueEngine`).
class AppwriteJobStore implements JobStore {
  /// Creates a store over [client] for [databaseId].
  AppwriteJobStore({required Client client, required this.databaseId})
    : _tablesDb = TablesDB(client);

  /// The database holding the tables.
  final String databaseId;

  final TablesDB _tablesDb;

  static String _claimRowId(String jobId, int attempt) => '${jobId}_$attempt';

  @override
  Future<void> insertJob(Job job) async {
    await _tablesDb.createRow(
      databaseId: databaseId,
      tableId: jobsTable,
      rowId: job.id,
      data: <String, dynamic>{
        'type': job.type,
        'payload': jsonEncode(job.payload),
        'priority': job.priority.name,
        'maxAttempts': '${job.maxAttempts}',
        'availableAt': _time(job.availableAt),
        'createdAt': _time(job.createdAt),
        'sortKey': job.sortKey,
        'status': JobStatus.queued.name,
      },
    );
  }

  @override
  Future<Job?> findJob(String id) async {
    try {
      return _toJob(
        await _tablesDb.getRow(
          databaseId: databaseId,
          tableId: jobsTable,
          rowId: id,
        ),
      );
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<Job>> nextCandidates({
    required DateTime now,
    required int limit,
    Set<String>? types,
  }) async {
    final typeQuery = <String>[
      if (types != null) Query.equal('type', types.toList()),
    ];
    final queued = await _tablesDb.listRows(
      databaseId: databaseId,
      tableId: jobsTable,
      queries: <String>[
        Query.equal('status', <String>[JobStatus.queued.name]),
        Query.lessThanEqual('availableAt', _time(now)),
        ...typeQuery,
        Query.orderAsc('sortKey'),
        Query.limit(limit),
      ],
    );
    final jobs = queued.rows.map(_toJob).toList();
    if (jobs.length >= limit) return jobs;
    // Jobs whose worker died: cached running, with a lease that ran out.
    final expired = await _tablesDb.listRows(
      databaseId: databaseId,
      tableId: jobsTable,
      queries: <String>[
        Query.equal('status', <String>[JobStatus.running.name]),
        Query.lessThanEqual('leaseUntil', _time(now)),
        ...typeQuery,
        Query.limit(limit - jobs.length),
      ],
    );

    return <Job>[...jobs, ...expired.rows.map(_toJob)];
  }

  @override
  Future<void> setJobStatus(
    String jobId,
    JobStatus status, {
    DateTime? leaseUntil,
  }) async {
    try {
      await _tablesDb.updateRow(
        databaseId: databaseId,
        tableId: jobsTable,
        rowId: jobId,
        data: <String, dynamic>{
          'status': status.name,
          'leaseUntil': leaseUntil == null ? null : _time(leaseUntil),
        },
      );
    } on AppwriteException catch (e) {
      if (e.code != HttpStatus.notFound) rethrow;
    }
  }

  @override
  Future<List<JobClaim>> claimsOf(String jobId) async {
    final claims = <JobClaim>[];
    String? after;
    while (true) {
      final page = await _tablesDb.listRows(
        databaseId: databaseId,
        tableId: jobClaimsTable,
        queries: <String>[
          Query.equal('jobId', <String>[jobId]),
          Query.limit(_pageSize),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      claims.addAll(page.rows.map(_toClaim));
      if (page.rows.length < _pageSize) return claims;
      after = page.rows.last.$id;
    }
  }

  @override
  Future<void> insertClaim(JobClaim claim) async {
    try {
      await _tablesDb.createRow(
        databaseId: databaseId,
        tableId: jobClaimsTable,
        rowId: _claimRowId(claim.jobId, claim.attempt),
        data: _claimData(claim),
      );
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.conflict) {
        throw DuplicateClaimError(claim.jobId, claim.attempt);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateClaim(JobClaim claim) async {
    await _tablesDb.updateRow(
      databaseId: databaseId,
      tableId: jobClaimsTable,
      rowId: _claimRowId(claim.jobId, claim.attempt),
      data: _claimData(claim),
    );
  }

  static String _time(DateTime time) => time.toUtc().toIso8601String();

  static Map<String, dynamic> _claimData(JobClaim claim) => <String, dynamic>{
    'jobId': claim.jobId,
    'attempt': '${claim.attempt}',
    'workerId': claim.workerId,
    'leaseExpiresAt': _time(claim.leaseExpiresAt),
    'state': claim.state.name,
    'result': claim.result == null ? null : jsonEncode(claim.result),
    'error': claim.error,
    'finishedAt': ?claim.finishedAt?.toUtc().toIso8601String(),
  };

  static Job _toJob(models.Row row) => Job(
    id: row.$id,
    type: row.data['type'] as String,
    payload: Map<String, dynamic>.from(
      jsonDecode(row.data['payload'] as String) as Map,
    ),
    priority: JobPriority.values.byName(row.data['priority'] as String),
    maxAttempts: int.parse(row.data['maxAttempts'] as String),
    availableAt: DateTime.parse(row.data['availableAt'] as String),
    createdAt: DateTime.parse(row.data['createdAt'] as String),
  );

  static JobClaim _toClaim(models.Row row) {
    final result = row.data['result'] as String?;
    final finishedAt = row.data['finishedAt'] as String?;

    return JobClaim(
      jobId: row.data['jobId'] as String,
      attempt: int.parse(row.data['attempt'] as String),
      workerId: row.data['workerId'] as String,
      leaseExpiresAt: DateTime.parse(row.data['leaseExpiresAt'] as String),
      state: JobClaimState.values.byName(row.data['state'] as String),
      result: result == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(result) as Map),
      error: row.data['error'] as String?,
      finishedAt: finishedAt == null ? null : DateTime.parse(finishedAt),
    );
  }
}
