import 'package:api/src/action_context.dart';
import 'package:api/src/actions/jobs/appwrite_job_store.dart';
import 'package:api/src/actions/jobs/handle_jobs_request.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:jobs/jobs.dart';

/// The `jobs` action: every state change of the leased job queue
/// (enqueue, claim, heartbeat, complete, fail, release, status) runs here, so
/// the rules live in one place (`JobQueueEngine`) and a worker is just an
/// HTTP client of it.
///
/// **Auth.** `requiresUser` is true, and the router's `x-appwrite-user-id`
/// must then be in the `JOBS_WORKER_USER_IDS` variable; see
/// `handleJobsRequest` for why a signed-in worker identity and not a shared
/// secret. Code inside the Function enqueues by building a `JobQueueEngine`
/// over `AppwriteJobStore` itself rather than calling this action.
class JobsAction implements ApiAction {
  /// Creates the action.
  const JobsAction();

  @override
  String get name => 'jobs';

  @override
  bool get requiresUser => true;

  /// Rows of `jobs` and `job_claims`.
  @override
  Set<String> get scopes => const <String>{
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
  };

  @override
  String get failureMessage => 'Job operation failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final queue = JobQueueEngine(
      store: AppwriteJobStore(
        client: context.client,
        databaseId: templateSchema.databaseId,
      ),
      newId: ID.unique,
    );

    return handleJobsRequest(
      callerUserId: context.callerUserId,
      workerUserIds: workerUsersFrom(context.environment),
      body: context.body,
      queue: queue,
    );
  }
}
