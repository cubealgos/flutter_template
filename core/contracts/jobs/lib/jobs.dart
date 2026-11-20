/// Backend-agnostic leased job queue: the `JobQueue` interface, its models
/// (`Job`, `JobClaim`, `JobLease`), the derived `JobStatus`, the typed
/// `JobError` hierarchy, `JobQueueEngine` (the one implementation of the
/// rules) over a `JobStore`, `JobWire` and in-memory fakes for tests.
///
/// `backend/appwrite/functions/api`'s `jobs` action runs `JobQueueEngine`
/// against Appwrite tables; `backend/appwrite/adapters`'s `AppwriteJobQueue`
/// is the client that calls it. Split into one file per declared type under
/// `src/` (matching this workspace's `prefer_match_file_name` lint) — this
/// file just re-exports all of them, mirroring `core/contracts/teams`.
library;

export 'src/duplicate_claim_error.dart';
export 'src/fake_job_queue.dart';
export 'src/in_memory_job_store.dart';
export 'src/job.dart';
export 'src/job_claim.dart';
export 'src/job_claim_state.dart';
export 'src/job_error.dart';
export 'src/job_lease.dart';
export 'src/job_priority.dart';
export 'src/job_queue.dart';
export 'src/job_queue_engine.dart';
export 'src/job_status.dart';
export 'src/job_store.dart';
export 'src/job_wire.dart';
export 'src/new_job.dart';
