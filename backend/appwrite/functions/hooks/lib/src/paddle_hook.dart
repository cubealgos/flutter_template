import 'package:api/billing_stores.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:billing/billing.dart';
import 'package:hooks/src/hook_request.dart';
import 'package:hooks/src/hook_response.dart';
import 'package:hooks/src/webhook_hook.dart';
import 'package:paddle_billing/paddle_billing.dart';

/// 200.
const int _ok = 200;

/// 400.
const int _badRequest = 400;

/// 401.
const int _unauthorized = 401;

/// 500.
const int _serverError = 500;

/// Builds the engine a request uses, over the request's client.
typedef BillingEngineFactory = BillingEngine Function(HookRequest request);

BillingEngine _appwriteEngine(HookRequest request) => BillingEngine(
  ledger: AppwriteBillingLedger(
    client: request.client,
    databaseId: templateSchema.databaseId,
  ),
  entitlements: AppwriteEntitlementStore(
    client: request.client,
    databaseId: templateSchema.databaseId,
  ),
);

/// The Paddle Billing webhook (`/paddle`).
///
/// 1. **Signature first**, over the exact raw bytes (`HookRequest.rawBody`),
///    with `PADDLE_WEBHOOK_SECRET`: a missing, malformed, stale or wrong one
///    is a 401 and nothing is read or written; an unset secret is a 500 (the
///    hook never accepts what it cannot verify).
/// 2. Parse the event (400 if Paddle sent something undocumented).
/// 3. `BillingEngine.process`: the ledger row first, the entitlement only
///    after; a replay is a 200 that changes nothing.
///
/// A store failure is a 500 so Paddle retries; the retry is a replay for the
/// rows already written.
class PaddleHook implements WebhookHook {
  /// Creates the hook; [engineFor] and [clock] are replaceable for tests.
  PaddleHook({DateTime Function()? clock, this.engineFor = _appwriteEngine})
    : _clock = clock ?? (() => DateTime.now().toUtc());

  /// Builds the engine of a request.
  final BillingEngineFactory engineFor;

  final DateTime Function() _clock;

  @override
  String get path => '/paddle';

  @override
  Future<HookResponse> handle(HookRequest request) async {
    final config = PaddleConfig.fromEnvironment(request.environment);
    final secret = config.webhookSecret;
    if (secret == null) {
      request.log?.call('paddle hook: PADDLE_WEBHOOK_SECRET is not set');

      return _answer(_serverError, 'not_configured');
    }
    final verdict = PaddleSignature.verify(
      rawBody: request.rawBody,
      header: request.headers[PaddleSignature.headerName],
      secret: secret,
      now: _clock(),
      tolerance: config.signatureTolerance,
    );
    if (verdict != SignatureVerdict.valid) {
      request.log?.call('paddle hook: signature ${verdict.name}');

      return _answer(_unauthorized, 'invalid_signature');
    }
    final ProviderEvent event;
    try {
      event = PaddleEventParser(config.plans).parse(request.rawBody);
    } on PaddleParseException catch (e) {
      request.log?.call('paddle hook: $e');

      return _answer(_badRequest, 'invalid_event');
    }
    final outcome = await engineFor(request).process(event);

    return HookResponse(
      statusCode: _ok,
      body: <String, dynamic>{
        'status': outcome.status.name,
        'recorded': outcome.recorded,
        'applied': outcome.applied,
      },
    );
  }

  HookResponse _answer(int status, String error) =>
      HookResponse(statusCode: status, body: <String, dynamic>{'error': error});
}
