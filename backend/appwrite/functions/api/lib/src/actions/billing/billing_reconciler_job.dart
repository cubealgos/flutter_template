import 'package:api/src/action_context.dart';
import 'package:api/src/billing/appwrite_billing_ledger.dart';
import 'package:api/src/billing/appwrite_entitlement_store.dart';
import 'package:api/src/scheduled_job.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:billing/billing.dart';
import 'package:http/http.dart' as http;
import 'package:paddle_billing/paddle_billing.dart';

/// Builds the reconciler a run uses, from the run's context and `config`; null
/// when there is no provider to compare with. Replaceable for tests.
typedef ReconcilerFactory =
    BillingReconciler? Function(ActionContext context, PaddleConfig config);

BillingReconciler? _paddleReconciler(
  ActionContext context,
  PaddleConfig config,
) {
  final key = config.apiKey;
  if (key == null) return null;

  return BillingReconciler(
    provider: PaddleProviderSubscriptions(
      paddle: PaddleApi(httpClient: http.Client(), key: key),
      plans: config.plans,
    ),
    entitlements: AppwriteEntitlementStore(
      client: context.client,
      databaseId: templateSchema.databaseId,
    ),
    // The reconciler is handed the ledger's read side only.
    ledger: AppwriteBillingLedger(
      client: context.client,
      databaseId: templateSchema.databaseId,
    ),
  );
}

/// The scheduled reconciler: hourly, it compares Paddle's view of
/// each subscription with the ledger and the entitlement, **corrects the
/// entitlement from Paddle's data**, and **logs every divergence** (one line
/// each, plus a summary) through the run's log, the only report channel a
/// Function has. It never writes the ledger (`BillingReconciler` holds only a
/// `BillingLedgerReader`). Register it wrapped in `OncePerSlotJob`.
///
/// Does nothing, and says so, while `PADDLE_API_KEY` is unset.
class BillingReconcilerJob implements ScheduledJob {
  /// Creates the job; [reconcilerFor] is replaceable for tests.
  const BillingReconcilerJob({this.reconcilerFor = _paddleReconciler});

  /// Builds the reconciler of a run.
  final ReconcilerFactory reconcilerFor;

  @override
  String get name => 'billing_reconciler';

  @override
  Duration get interval => const Duration(hours: 1);

  /// Reads and writes `billing_entitlements`, reads `billing_events`.
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
  Future<void> run(ActionContext context, {required int slot}) async {
    final reconciler = reconcilerFor(
      context,
      PaddleConfig.fromEnvironment(context.environment),
    );
    if (reconciler == null) {
      context.log?.call('$name: PADDLE_API_KEY is not set, skipped');

      return;
    }
    final report = await reconciler.run();
    for (final divergence in report.divergences) {
      context.log?.call('$name: divergence $divergence');
    }
    context.log?.call(
      '$name: checked ${report.checked}, '
      '${report.divergences.length} divergence(s)',
    );
  }
}
