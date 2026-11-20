import 'package:api/src/function_response.dart';
import 'package:billing/billing.dart';
import 'package:paddle_billing/paddle_billing.dart';

/// The HTTP status of a successful call.
const int _ok = 200;

/// The HTTP status of an operation the action does not know.
const int _badRequest = 400;

/// Runs one billing operation for [callerUserId] and builds the response.
///
/// The body is `{"op": <name>, "owner": "user:<id>"|"team:<id>", ...}`:
///
/// - `start_checkout` (`plan`, `quantity`) answers `{url, transactionId}`;
/// - `open_portal` answers `{url}`;
/// - `update_quantity` (`quantity`) answers the entitlement the provider's
///   answer implies;
/// - `entitlement` answers the current one;
/// - `entitlement_of` is the same for a **worker** (an ID in
///   [workerUserIds]) that gates server jobs on someone's entitlement without
///   being a member of the team.
///
/// An omitted `owner` is the caller's own user. The caller's identity is the
/// router's `x-appwrite-user-id`, never the body; whether it may act for the
/// owner is the service's `BillingAccess`. Every `BillingError` becomes its
/// status and `{"error": {"code", "message"}}`; anything else propagates to
/// the router, which answers 500.
Future<FunctionResponse> handleBillingRequest({
  required String callerUserId,
  required Set<String> workerUserIds,
  required Map<String, dynamic> body,
  required BillingService service,
}) async {
  try {
    return await _run(callerUserId, workerUserIds, body, service);
  } on BillingError catch (e) {
    return FunctionResponse(
      body: BillingWire.errorToJson(e),
      statusCode: e.statusCode,
    );
  }
}

Future<FunctionResponse> _run(
  String caller,
  Set<String> workers,
  Map<String, dynamic> body,
  BillingService service,
) async {
  final owner = _ownerOf(body, caller);
  final op = body['op'];
  switch (op) {
    case 'start_checkout':
      final session = await service.startCheckout(
        caller: caller,
        plan: _string(body, 'plan'),
        quantity: _quantity(body),
        owner: owner,
      );

      return _json(BillingWire.checkoutToJson(session));
    case 'open_portal':
      final session = await service.openPortal(caller: caller, owner: owner);

      return _json(BillingWire.portalToJson(session));
    case 'update_quantity':
      final entitlement = await service.updateQuantity(
        caller: caller,
        owner: owner,
        quantity: _quantity(body),
      );

      return _json(BillingWire.entitlementToJson(entitlement));
    case 'entitlement':
      return _json(
        BillingWire.entitlementToJson(
          await service.entitlement(caller: caller, owner: owner),
        ),
      );
    case 'entitlement_of':
      if (!workers.contains(caller)) {
        throw const BillingForbiddenError('Not a configured worker.');
      }

      return _json(
        BillingWire.entitlementToJson(await service.entitlementOf(owner)),
      );
    default:
      return FunctionResponse(
        body: BillingWire.errorToJson(
          const BillingInvalidError('Unknown billing operation.'),
        ),
        statusCode: _badRequest,
      );
  }
}

BillingOwner _ownerOf(Map<String, dynamic> body, String caller) {
  final raw = body['owner'];
  if (raw == null) return BillingOwner.user(caller);

  return BillingOwner.tryParse(raw) ??
      (throw const BillingInvalidError('"owner" is user:<id> or team:<id>.'));
}

String _string(Map<String, dynamic> body, String key) {
  final value = body[key];

  return value is String && value.isNotEmpty
      ? value
      : throw BillingInvalidError('"$key" is required.');
}

int _quantity(Map<String, dynamic> body) {
  final value = body['quantity'];

  return value is int && value >= 1
      ? value
      : throw const BillingInvalidError('"quantity" is a whole number >= 1.');
}

FunctionResponse _json(Map<String, dynamic> body) =>
    FunctionResponse(body: body, statusCode: _ok);
