/// The Paddle Billing adapter for `core/contracts/billing`: signature
/// verification, the webhook event parser, the API client and the
/// server-side `BillingService`. Pure Dart; the Appwrite Functions `api` and
/// `hooks` run it.
///
/// Split into one file per declared type under `src/` (matching this
/// workspace's `prefer_match_file_name` lint) - this file just re-exports them.
library;

export 'src/billing_access.dart';
export 'src/billing_service.dart';
export 'src/paddle_api.dart';
export 'src/paddle_api_exception.dart';
export 'src/paddle_config.dart';
export 'src/paddle_event_parser.dart';
export 'src/paddle_parse_exception.dart';
export 'src/paddle_plans.dart';
export 'src/paddle_provider_subscriptions.dart';
export 'src/paddle_signature.dart';
export 'src/paddle_subscription_mapper.dart';
export 'src/signature_verdict.dart';
