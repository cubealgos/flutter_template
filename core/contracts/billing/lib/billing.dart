/// Backend-agnostic web billing: the `Billing` interface and its models,
/// `Entitlement` (a function of state and time), the append-only
/// `BillingLedger`, `BillingEngine`, `BillingReconciler` and in-memory
/// fakes for tests.
///
/// `backend/paddle` is the merchant-of-record adapter and
/// `backend/appwrite/functions/{api,hooks}` run the engine on Appwrite.
/// Split into one file per declared type under `src/` (matching this
/// workspace's `prefer_match_file_name` lint) - this file just re-exports them.
library;

export 'src/billing.dart';
export 'src/billing_engine.dart';
export 'src/billing_error.dart';
export 'src/billing_ledger.dart';
export 'src/billing_ledger_reader.dart';
export 'src/billing_owner.dart';
export 'src/billing_owner_kind.dart';
export 'src/billing_reconciler.dart';
export 'src/billing_wire.dart';
export 'src/checkout_session.dart';
export 'src/divergence.dart';
export 'src/divergence_kind.dart';
export 'src/entitlement.dart';
export 'src/entitlement_policy.dart';
export 'src/entitlement_reader.dart';
export 'src/entitlement_status.dart';
export 'src/entitlement_store.dart';
export 'src/fake_billing.dart';
export 'src/in_memory_billing_ledger.dart';
export 'src/in_memory_entitlement_store.dart';
export 'src/ledger_change.dart';
export 'src/ledger_entry.dart';
export 'src/ledger_kind.dart';
export 'src/portal_session.dart';
export 'src/provider_event.dart';
export 'src/provider_status.dart';
export 'src/provider_subscriptions.dart';
export 'src/reconcile_report.dart';
export 'src/scheduled_action.dart';
export 'src/scheduled_change.dart';
export 'src/state_source.dart';
export 'src/subscription_state.dart';
export 'src/webhook_outcome.dart';
export 'src/webhook_status.dart';
