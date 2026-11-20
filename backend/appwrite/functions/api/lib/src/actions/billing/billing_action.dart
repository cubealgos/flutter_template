import 'package:api/src/action_context.dart';
import 'package:api/src/actions/billing/handle_billing_request.dart';
import 'package:api/src/actions/jobs/handle_jobs_request.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/billing/appwrite_billing_access.dart';
import 'package:api/src/billing/appwrite_entitlement_store.dart';
import 'package:api/src/function_response.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:http/http.dart' as http;
import 'package:paddle_billing/paddle_billing.dart';

/// The `billing` action: checkout, customer portal, prorated
/// quantity changes and the entitlement read, for a signed-in caller acting
/// for themselves or a team. See `handleBillingRequest` for the operations.
///
/// It **only reads** entitlements and never writes the ledger: the
/// entitlement follows Paddle's webhook (the `hooks` Function), so there is one
/// path into it. Server code that must gate on an entitlement builds an
/// `EntitlementReader` over `AppwriteEntitlementStore`, or a worker calls the
/// `entitlement_of` operation.
class BillingAction implements ApiAction {
  /// Creates the action.
  const BillingAction();

  @override
  String get name => 'billing';

  @override
  bool get requiresUser => true;

  /// Reads of `billing_entitlements` and of team memberships.
  @override
  Set<String> get scopes => const <String>{
    'tables.read',
    'collections.read',
    'documents.read',
    'teams.read',
  };

  @override
  String get failureMessage => 'Billing operation failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final config = PaddleConfig.fromEnvironment(context.environment);
    final key = config.apiKey;
    final service = BillingService(
      access: AppwriteBillingAccess(context.client),
      entitlements: AppwriteEntitlementStore(
        client: context.client,
        databaseId: templateSchema.databaseId,
      ),
      plans: config.plans,
      policy: config.policy,
      api: key == null ? null : PaddleApi(httpClient: http.Client(), key: key),
      log: context.log,
    );

    return handleBillingRequest(
      callerUserId: context.callerUserId ?? '',
      workerUserIds: workerUsersFrom(context.environment),
      body: context.body,
      service: service,
    );
  }
}
